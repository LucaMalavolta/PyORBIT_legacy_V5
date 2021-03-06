from abstract_common import *


class CommonPlanets(AbstractCommon):
    """
    Inherited class from AbstractCommon

    For computational reason it is better to fit :math:`\sqrt{e}\sin{\omega}` and :math:`\sqrt{e}\cos{\omega}`.
    :func:`define_special_variables_bounds` and :func:`define_special_starting_point` must be redefined

    Attributes:
        :model_class (string): identify the kind of class
        :list_pams: all the possible parameters that can be assigned to a planet are listed here
        :default_bounds: these default boundaries are used when the user does not define them in the yaml file
        :recenter_pams: circular parameters that may need a recentering around the most likely value after the global
            optimization run
        :period_average: variable used only by TRADES
    """

    model_class = 'planet'

    list_pams = {
        'P': 'LU',  # Period, log-uniform prior
        'K': 'LU',  # RV semi-amplitude, log-uniform prior
        'f': 'U',  # RV curve phase, log-uniform
        'e': 'U',  # eccentricity, uniform prior - to be fixed
        'o': 'U',  # argument of pericenter (in radians)
        'M': 'LU',  # Mass in Earth masses
        'i': 'U',  # orbital inclination (in degrees)
        'lN': 'U',  # longitude of ascending node
        'R': 'U',  # planet radius (in units of stellar radii)
        'a': 'U'  # semi-major axis (in units of stellar radii)
    }

    default_bounds = {
        'P': [0.4, 100000.0],
        'K': [0.5, 2000.0],
        'f': [0.0, 2 * np.pi],
        'ecoso': [-1.0, 1.0],
        'esino': [-1.0, 1.0],
        'e': [0.0, 1.0],
        'o': [0.0, 2 * np.pi],
        # Used by TTVfast/TRADES
        'M': [0.5, 1000.0],  # Fix the unit
        'i': [0.0, 180.0],
        'lN': [0.0, 2 * np.pi],
        # Used by BATMAN
        'R': [0.00001, 0.5],  # Fix the unit
        'a': [0.00001, 50.]  # Fix the unit
    }

    """ Must be the same parameters as in list_pams, because priors are applied only to _physical_ parameters """
    default_priors = {
        #'P': ['ModifiedJeffreys', [1.00]],
        #'K': ['ModifiedJeffreys', [1.00]],
        'P': ['Uniform', []],
        'K': ['Uniform', []],
        'f': ['Uniform', []],
        'e': ['BetaDistribution', [0.71, 2.57]],
        'o': ['Uniform', []],
        'M': ['Uniform', []],  # Fix the unit
        'i': ['Uniform', []],
        'lN': ['Uniform', []],
        'R': ['Uniform', []],  # Fix the unit
        'a': ['Uniform', []]  # Fix the unit
    }

    recenter_pams = {'f', 'o', 'lN'}

    # Variable used only by TRADES
    period_average = None

    def define_special_variables_bounds(self, ndim, var):
        """ Boundaries definition for eccentricity :math:`e` and argument of pericenter :math:`\omega`

        The internal variable to be fitted are :math:`\sqrt{e}\sin{\omega}` and :math:`\sqrt{e}\cos{\omega}`.
        With this parametrization it is not possible to naturally put a boundary to :math:`e` without affecting the
        :math:`\omega`.
        Additionally the subroutine will check if either :math:`e` or :math:`\omega` have been provided as fixed values.
        If true, the parametrization will consist of :math:`e` or :math:`\omega`  instead of
        :math:`\sqrt{e}\sin{\omega}` and :math:`\sqrt{e}\cos{\omega}`

        Args:
            :ndim: number of parameters already processed by other models
            :var: input variable, either :math:`e` or :math:`\omega`
        Returns:
            :ndim: updated dimensionality of the problem
            :bounds_list: additional boundaries to be added to the original list
        """

        bounds_list = []

        if var == 'P':
            if var in self.fix_list:
                self.period_average = self.fix_list['P'][0]
            else:
                if var in self.bounds:
                    bounds_tmp = self.bounds[var]
                else:
                    bounds_tmp = self.default_bounds[var]
                self.period_average = np.average(bounds_tmp)
            return ndim, bounds_list

        if not(var == "e" or var == "o"):
            return ndim, bounds_list

        if 'e' in self.fix_list or \
           'o' in self.fix_list:
            return ndim, bounds_list

        if 'coso' in self.variable_sampler or \
            'esino' in self.variable_sampler:
            return ndim, bounds_list

        self.transformation['e'] = get_2var_e
        self.variable_index['e'] = [ndim, ndim + 1]
        self.transformation['o'] = get_2var_o
        self.variable_index['o'] = [ndim, ndim + 1]

        self.variable_sampler['ecoso'] = ndim
        self.variable_sampler['esino'] = ndim + 1
        bounds_list.append(self.default_bounds['ecoso'])
        bounds_list.append(self.default_bounds['esino'])

        for var in ['e', 'o']:
            if var not in self.prior_pams:

                if var in self.bounds:
                    self.prior_pams[var] = self.bounds[var]
                else:
                    self.prior_pams[var] = self.default_bounds[var]

                self.prior_kind[var] = 'Uniform'

        ndim += 2

        return ndim, bounds_list

    def define_special_starting_point(self, starting_point, var):
        """
        Eccentricity and argument of pericenter require a special treatment

        since they can be provided as fixed individual values or may need to be combined
        in :math:`\sqrt{e}\sin{\omega}` and :math:`\sqrt{e}\cos{\omega}` if are both free variables

        Args:
            :starting_point:
            :var:
        Returns:
            :bool:

        """

        if not (var == "e" or var == "o"):
            return False

        if 'ecoso' in self.variable_sampler and \
                        'esino' in self.variable_sampler:

            if 'e' in self.starts and 'o' in self.starts:
                starting_point[self.variable_sampler['ecoso']] = \
                    np.sqrt(self.starts['e']) * np.cos(self.starts['o'])
                starting_point[self.variable_sampler['esino']] = \
                    np.sqrt(self.starts['e']) * np.sin(self.starts['o'])

            elif 'ecoso' in self.starts and 'esino' in self.starts:
                starting_point[self.variable_sampler['ecoso']] = self.starts['ecoso']
                starting_point[self.variable_sampler['ecoso']] = self.starts['esino']

        return True

    def special_fix_population(self, population):

        n_pop = np.size(population, axis=0)
        if 'esino' in self.variable_sampler and \
           'ecoso' in self.variable_sampler:
                esino_list = self.variable_sampler['esino']
                ecoso_list = self.variable_sampler['ecoso']
                e_pops = population[:, esino_list] ** 2 + population[:, ecoso_list] ** 2
                o_pops = np.arctan2(population[:, esino_list], population[:, ecoso_list], dtype=np.double)
                # e_mean = (self[planet_name].bounds['e'][0] +
                # self[planet_name].bounds['e'][1]) / 2.
                for ii in xrange(0, n_pop):
                    if not self.bounds['e'][0] + 0.02 <= e_pops[ii] < \
                                    self.bounds['e'][1] - 0.02:
                        e_random = np.random.uniform(self.bounds['e'][0],
                                                     self.bounds['e'][1])
                        population[ii, esino_list] = np.sqrt(e_random) * np.sin(o_pops[ii])
                        population[ii, ecoso_list] = np.sqrt(e_random) * np.cos(o_pops[ii])

