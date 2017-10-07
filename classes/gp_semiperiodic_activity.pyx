from common import *
from abstract_common import *
from abstract_model import *

class GaussianProcess_QuasiPeriodicActivity(AbstractModel):
    ''' Three parameters out of four are the same for all the datasets, since they are related to
    the properties of the physical process rather than the observed effects on a dataset
     From Grunblatt+2015, Affer+2016
     - theta: is usually related to the rotation period of the star( or one of its harmonics);
     - lambda: is the correlation decay timescale, and it can be related to the lifetime of the active regions.
     - omega: is the length scale of the periodic component, and can be linked to the size evolution of the active regions;
     - h: represents the amplitude of the correlations '''

    internal_likelihood = True

    model_class = 'gp_quasiperiodic'

    list_pams_common = {
        'Prot': 'U', # Rotational period of the star
        'Pdec': 'U', # Decay timescale of activity
        'Oamp': 'LU' # Granulation of activity
    }

    list_pams_dataset = {
        'Hamp': 'U'  # Amplitude of the signal in the covariance matrix
    }

    recenter_pams_dataset = {}

    n_pams = 4

    """ Indexing is determined by the way the kernel is constructed, so it is specific of the Model and not of the 
    Common class"""
    gp_pams_index = {
        'Hamp': 0, # amp2
        'Pdec': 1, # metric
        'Oamp': 2, # gamma
        'Prot': 3 # ln_P
    }

    gp = {}

    def convert_val2gp(self, input_pams):
        """
        :param input_pam: dictonary with the 'physically meaningful' parameters of the GP kernel
        :return: dictonary with the parameters to be fed to 'george'
        WARNING: this subroutine is HIGHLY specific of your choice of the kernel! I reccomend to
        create a new Class with different transformations if you are planning of using a different
        kernel combination
        """
        output_pams = np.zeros(self.n_pams, dtype=np.double)

        """ You must check _george_ documentation (and possibily do a lot of testing) to know how to convert physical 
        values to the parameter vector accepted by george.set_parameter_vector() function. Note: these values may be 
        different from ones accepted by the kernel
        """
        output_pams[self.gp_pams_index['Hamp']] = np.log(input_pams['Hamp'])*2
        output_pams[self.gp_pams_index['Pdec']] = np.log(input_pams['Pdec'])*2
        output_pams[self.gp_pams_index['Oamp']] = 1. / (2.*input_pams['Oamp'] ** 2)
        output_pams[self.gp_pams_index['Prot']] = np.log(input_pams['Prot'])

        return output_pams

    def convert_gp2val(self, input_pams):
        """
        :param input_pam: dictonary with the parameters to be fed to 'george'
        :return: dictonary with the 'physically meaningful' parameters of the GP kernel
        WARNING: this subroutine is HIGHLY specific of your choice of the kernel! I reccomend to
        create a new Class with different transformations if you are planning of using a different
        kernel combination
        """
        return {
            'Hamp': np.exp(input_pams[self.gp_pams_index['Hamp']]/2.0),
            'Pdec': np.exp(input_pams[self.gp_pams_index['Pdec']] / 2.0),
            'Oamp': np.sqrt(1. / (2.*input_pams[self.gp_pams_index['Oamp']])),
            'Prot': np.exp(input_pams[self.gp_pams_index['Prot']])
        }

    def setup_dataset(self, dataset):
        self.define_kernel(dataset)
        return

    def define_kernel(self, dataset):

        gp_pams = np.ones(self.n_pams)
        """ Kernel initialized with fake values... don't worry, they'll be overwritten soon"""
        kernel = np.exp(gp_pams[0]) * \
                      george.kernels.ExpSquaredKernel(metric=np.exp(gp_pams[1])) * \
                      george.kernels.ExpSine2Kernel(gamma=gp_pams[2], log_period=gp_pams[3])



        """
         gp_pams[0] = h^2 -> h^2 * ExpSquaredKernel * ExpSine2Kernel
           -> set_parameter_vector() accepts the natural logarithm of this value
         gp_pams[1] = metric = r^2 = lambda**2  -> ExpSquaredKernel(metric=r^2)
           -> set_parameter_vector() accepts the natural logarithm of this value
         gp_pams[2] = Gamma =  1/ (2 omega**2) -> ExpSine2Kernel(gamma, ln_period)
         gp_pams[3] = ln_theta = ln_Period -> ExpSine2Kernel(gamma, ln_period)
         
        """

        self.gp[dataset.name_ref] = george.GP(kernel)
        #self.gp[dataset.name_ref] = george.GP(kernel, solver=george.HODLRSolver, mean=0.00)

        """ I've decided to add the jitter in quadrature instead of using a constant kernel to allow the use of 
        different / selective jitter within the dataset
        """
        env = np.sqrt(dataset.e ** 2.0 + dataset.jitter ** 2.0)

        self.gp[dataset.name_ref].compute(dataset.x0, env)
        return

    def lnlk_compute(self, variable_value, dataset):
        """ 2 steps:
           1) theta parameters must be converted in physical units (e.g. from logarithmic to linear space)
           2) physical values must be converted to {\tt george} input parameters
        """
        gp_pams = self.convert_val2gp(variable_value)
        env = np.sqrt(dataset.e ** 2.0 + dataset.jitter ** 2.0)
        self.gp[dataset.name_ref].set_parameter_vector(gp_pams)
        self.gp[dataset.name_ref].compute(dataset.x0, env)
        #self.gp[dataset.name_ref].recompute()
        #print dataset.model[0]
        #print self.gp[dataset.name_ref].log_likelihood(dataset.y - dataset.model, quiet=True)
        return self.gp[dataset.name_ref].lnlikelihood(dataset.y - dataset.model, quiet=True)

    def sample_predict(self, variable_value, dataset):

        gp_pams = self.convert_val2gp(variable_value)

        env = np.sqrt(dataset.e ** 2.0 + dataset.jitter ** 2.0)
        self.gp[dataset.name_ref].set_parameter_vector(gp_pams)
        self.gp[dataset.name_ref].compute(dataset.x0, env)

        return self.gp[dataset.name_ref].predict(dataset.y - dataset.model, dataset.x0)

    def sample_conditional(self, variable_value, dataset):

        gp_pams = self.convert_val2gp(variable_value)

        env = np.sqrt(dataset.e ** 2.0 + dataset.jitter ** 2.0)
        self.gp[dataset.name_ref].set_parameter_vector(gp_pams)
        self.gp[dataset.name_ref].compute(dataset.x0, env)

        return self.gp[dataset.name_ref].sample_conditional(dataset.y - dataset.model, dataset.x0)

