from abstract_common import *
from abstract_model import *
import numpy.polynomial.polynomial


class CommonPolynomialTrend(AbstractCommon):
    ''' This class must be created for each planet in the system
            model_name is the way the planet is identified
    '''

    model_class = 'polynomial_trend'

    "polynomial trend up to 10th order"
    list_pams = {
        'c1': 'U',  # order 1
        'c2': 'U',  # order 2
        'c3': 'U',  # order 3
        'c4': 'U',  # order 4
        'c5': 'U',  # order 5
        'c6': 'U',  # order 6
        'c7': 'U',  # order 7
        'c8': 'U',  # order 8
        'c9': 'U',  # order 9
    }

    """These default boundaries are used when the user does not define them in the yaml file"""
    default_bounds = {
        'c1': [-10.0, 10.0], # 10 m/s/day would be already an unbelievable value
        'c2': [-1.0, 1.0],
        'c3': [-1.0, 1.0],
        'c4': [-1.0, 1.0],
        'c5': [-1.0, 1.0],
        'c6': [-1.0, 1.0],
        'c7': [-1.0, 1.0],
        'c8': [-1.0, 1.0],
        'c9': [-1.0, 1.0]
    }

    recenter_pams = {}


class PolynomialTrend(AbstractModel):

    model_class = 'polynomial_trend'
    list_pams_common = {}
    list_pams_dataset = {}

    recenter_pams_dataset = {}

    order = 1

    def initialize_model(self, mc, **kwargs):
        """ A special kind of initialization is required for this module, since it has to take a second dataset
        and check the corrispondence with the points

        """
        if 'order' in kwargs:
            self.order = kwargs['order']

        for i_order in xrange(1, self.order+1):
            var = 'c'+repr(i_order)
            self.list_pams_common.update({var: 'U'})

            # ???????????????
            self.default_priors.update({var: ['Uniform', []]})

    def compute(self, variable_value, dataset, x0_input=None):

        coeff = np.zeros(self.order+1)
        for i_order in xrange(1, self.order+1):
            var = 'c'+repr(i_order)
            coeff[i_order] = variable_value[var]

        """ In our array, coefficient are sorted from the lowest degree to the highr
        Numpy Polinomials requires the inverse order (from high to small) as input"""
        # print variable_value
        # print coeff
        # print numpy.polynomial.polynomial.polyval(dataset.x0, coeff)

        if x0_input is None:
            return numpy.polynomial.polynomial.polyval(dataset.x0, coeff)
        else:
            return numpy.polynomial.polynomial.polyval(x0_input, coeff)
