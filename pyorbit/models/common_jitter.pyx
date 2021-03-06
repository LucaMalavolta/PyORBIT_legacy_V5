from abstract_common import *
from abstract_model import *


class CommonJitter(AbstractCommon):
    ''' Common offset for datasets in different files
    '''

    model_class = 'common_jitter'

    list_pams = {
        'jitter': 'LU',  # order 1
    }

    default_bounds = {}

    default_priors = {
            'jitter': ['Jeffreys', []]
    }

    recenter_pams = {}

    def common_initialization_with_dataset(self, dataset):
        if not self.default_bounds:
            min_jitter = np.min(dataset.e) / 100.
            max_jitter = np.max(dataset.e) * 100.
        else:
            min_jitter = min(self.default_bounds['jitter'][0], np.min(dataset.e) / 100.)
            max_jitter = max(self.default_bounds['jitter'][1], np.max(dataset.e) * 100.)
        self.default_bounds['jitter']= [min_jitter, max_jitter]
        dataset.shutdown_jitter()
        return


class Jitter(AbstractModel):

    model_class = 'common_jitter'
    list_pams_common = {'jitter': 'LU'}
    list_pams_dataset = {}

    recenter_pams_dataset = {}
    single_value_output = True

    def compute(self, variable_value, dataset, x0_input=None):
        return variable_value['jitter']



