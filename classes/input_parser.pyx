from common import *
from dataset import *
from planets import PlanetsCommonVariables
from gaussian import GaussianProcess_QuasiPeriodicActivity
from curvature import CurvatureCommonVariables
from correlations import CorrelationsCommonVariables
#from sinusoids import SinusoidsCommonVariables

define_type_to_class = {
    'planets': PlanetsCommonVariables,
    'gp_quasiperiodic': GaussianProcess_QuasiPeriodicActivity,
    'curvature': CurvatureCommonVariables,
    'correlation': CorrelationsCommonVariables
}


def yaml_parser(file_conf, mc):
    stream = file(file_conf, 'r')
    config_in = yaml.load(stream)

    conf_inputs = config_in['inputs']
    conf_models = config_in['models']
    conf_parameters = config_in['parameters']
    conf_solver = config_in['solver']

    for counter in conf_inputs:
        print conf_inputs[counter]['kind'], conf_inputs[counter]['file'], conf_inputs[counter]['models']
        dataset_name = conf_inputs[counter]['file']

        """ The keyword in dataset_dict and the name assigned internally to the databes must be the same
            or everything will fall apart """
        if 'Tcent' in conf_inputs[counter]['kind']:
            planet_name = 'Planet_' + repr(conf_inputs[counter]['Planet'])
            mc.dataset_dict[dataset_name] = \
                TransitCentralTimes(counter, conf_inputs[counter]['kind'], dataset_name, conf_inputs[counter]['models'])
            mc.dataset_dict[dataset_name].set_planet(planet_name)
            mc.t0_list[planet_name] = mc.dataset_dict[dataset_name]
        else:
            mc.dataset_dict[dataset_name] = \
                Dataset(counter, conf_inputs[counter]['kind'], dataset_name, conf_inputs[counter]['models'])

        mc.dataset_index[counter] = dataset_name

        if counter == 0:
            mc.Tref = mc.dataset_dict[dataset_name].Tref
        else:
            mc.dataset_dict[dataset_name].common_Tref(mc.Tref)

        if 'name' in conf_inputs[counter]:
            mc.dataset_dict[dataset_name].name = conf_inputs[counter]['name']
        else:
            mc.dataset_dict[dataset_name].name = 'unspecified'

        if 'boundaries' in conf_inputs[counter]:
            bound_conf = conf_inputs[counter]['boundaries']
            for var in bound_conf:
                mc.dataset_dict[dataset_name].bounds[var] = np.asarray(bound_conf[var], dtype=np.double)

        if 'starts' in conf_inputs[counter]:
            mc.starting_point_flag = True
            starts_conf = conf_inputs[counter]['starts']
            for var in starts_conf:
                mc.dataset_dict[dataset_name].starts[var] = np.asarray(starts_conf[var], dtype=np.double)

<<<<<<< HEAD
    mc.planet_name = config_in['output']
    mc.create_model_list()
=======
    mc.planet_name = config_in['Output']

    if 'Planets' in config_in:
        conf = config_in['Planets']
        for counter in conf:
            planet_name = 'Planet_' + repr(counter)
            planet_conf = conf[counter]
            mc.pcv.add_planet(planet_name)

            if 'Boundaries' in planet_conf:
                bound_conf = planet_conf['Boundaries']
                for var in bound_conf:
                    mc.pcv.bounds[planet_name][var] = np.asarray(bound_conf[var], dtype=np.double)

            if 'Fixed' in planet_conf:
                fixed_conf = planet_conf['Fixed']
                for var in fixed_conf:
                    mc.pcv.fix_list[planet_name][var] = np.asarray(fixed_conf[var], dtype=np.double)

            if 'Priors' in planet_conf:
                prior_conf = planet_conf['Priors']
                for var in prior_conf:
                    mc.pcv.prior_kind[planet_name][var] = prior_conf[var][0]
                    mc.pcv.prior_pams[planet_name][var] = np.asarray(prior_conf[var][1:], dtype=np.double)
                print mc.pcv.prior_kind
                print mc.pcv.prior_pams

            if 'Starts' in planet_conf:
                mc.starting_point_flag = True
                starts_conf = planet_conf['Starts']
                for var in starts_conf:
                    mc.pcv.starts[planet_name][var] = np.asarray(starts_conf[var], dtype=np.double)

            if 'Orbit' in planet_conf:
                # By default orbits are keplerians
                if planet_conf['Orbit'] == 'circular':
                    mc.pcv.switch_to_circular(planet_name)
                if planet_conf['Orbit'] == 'dynamical':
                    mc.pcv.switch_to_dynamical(planet_name)

            if 'Transit' in planet_conf:
                if planet_conf['Transit']:
                    mc.pcv.switch_on_transit(planet_name)

            if 'Inclination' in planet_conf:
                mc.pcv.inclination[planet_name] = planet_conf['Inclination']
            if 'Radius' in planet_conf:
                mc.pcv.radius[planet_name] = planet_conf['Radius']

    if 'Correlations' in config_in:
        conf = config_in['Correlations']
        correlation_common = False

        """ When including the specific values for each dataset association, the existence of common variables must have
            been already checked, just to avoid problems to those distracted users that include the Common block after
            the dataset-specific ones
        """
        for counter_ref in conf:
            if counter_ref is 'Common':
                correlation_common = True

        for counter_ref in conf:
            if counter_ref is 'Common':
                continue

            dataname_ref = mc.dataset_index[counter_ref]
            mc.cov.add_dataset(dataname_ref)
            #print ' --> ', conf[counter_ref]
            for counter_asc in conf[counter_ref]:
                dataname_asc = mc.dataset_index[counter_asc]
                mc.cov.add_associated_dataset(mc, dataname_ref, dataname_asc)
                free_zeropoint = False

                """ Apply common settings (if present) before overriding them with the specific values (if provided)"""
                if correlation_common:
                    common_conf = conf[counter_ref]['Common']

                    """ The xero point of the correlation plot is already included as a free parameter
                     as the offset of the associated dataset, so it is disabled by default. However there may be 
                     situations in which it is still needed to have it as a free parameter, so this option is given"""

                    if 'Free_ZeroPoint' not in common_conf or common_conf['Free_ZeroPoint'] is False:
                        mc.cov.fix_list[dataname_ref][dataname_asc]['correlation_0'] = 0.0000
                        free_zeropoint = True

                    """ By default the origin of the x axis of the independent parameter (usually an activity indicator)
                    is set to the median value of the parameter. The user has te option to specify a value"""
                    if 'Abscissa_zero' in common_conf:
                        mc.cov.x_zero[dataname_ref][dataname_asc] = common_conf['Abscissa_zero']

                    if 'Order' in common_conf:
                        mc.cov.order[dataname_ref][dataname_asc] = \
                            np.asarray(common_conf['Order'], dtype=np.int64)

                    if 'Boundaries' in common_conf:
                        bound_conf = common_conf['Boundaries']
                        for var in bound_conf:
                            mc.cov.bounds[dataname_ref][dataname_asc]['correlation_' + var] = \
                                np.asarray(bound_conf[var], dtype=np.double)

                    if 'Fixed' in common_conf:
                        fixed_conf = common_conf['Fixed']
                        for var in fixed_conf:
                            mc.cov.fix_list[dataname_ref][dataname_asc]['correlation_' + var] = \
                                np.asarray(fixed_conf[var], dtype=np.double)

                    if 'Priors' in common_conf:
                        prior_conf = conf[counter]['Priors']
                        for var in prior_conf:
                            mc.cov.prior_kind[dataname_ref][dataname_asc]['correlation_' + var] = prior_conf[var][0]
                            mc.cov.prior_pams[dataname_ref][dataname_asc]['correlation_' + var] = \
                                np.asarray(prior_conf[var][1:], dtype=np.double)

                    if 'Starts' in conf[counter]:
                        mc.starting_point_flag = True
                        starts_conf = common_conf['Starts']
                        for var in starts_conf:
                            mc.cov.starts[dataname_ref][dataname_asc]['correlation_' + var] = \
                                np.asarray(starts_conf[var], dtype=np.double)

                if free_zeropoint is False and \
                    ('Free_ZeroPoint' not in conf[counter_ref][counter_asc] or
                     conf[counter_ref][counter_asc]['Free_ZeroPoint'] is False):
                    mc.cov.fix_list[dataname_ref][dataname_asc]['correlation_0'] = 0.0000

                if 'Abscissa_zero' in conf[counter_ref][counter_asc]:
                    mc.cov.x_zero[dataname_ref][dataname_asc] = common_conf['Abscissa_zero']

                if 'Order' in conf[counter_ref][counter_asc]:
                    mc.cov.order[dataname_ref][dataname_asc] = \
                        np.asarray(conf[counter_ref][counter_asc]['Order'], dtype=np.int64)

                if 'Boundaries' in conf[counter_ref][counter_asc]:
                    bound_conf = conf[counter_ref][counter_asc]['Boundaries']
                    for var in bound_conf:
                        mc.cov.bounds[dataname_ref][dataname_asc]['correlation_' + var] = \
                            np.asarray(bound_conf[var], dtype=np.double)

                if 'Fixed' in conf[counter_ref][counter_asc]:
                    fixed_conf = conf[counter_ref][counter_asc]['Fixed']
                    for var in fixed_conf:
                        mc.cov.fix_list[dataname_ref][dataname_asc]['correlation_' + var] = \
                            np.asarray(fixed_conf[var], dtype=np.double)

                if 'Priors' in conf[counter_ref][counter_asc]:
                    prior_conf = conf[counter_ref][counter_asc]['Priors']
                    for var in prior_conf:
                        mc.cov.prior_kind[dataname_ref][dataname_asc]['correlation_' + var] = prior_conf[var][0]
                        mc.cov.prior_pams[dataname_ref][dataname_asc]['correlation_' + var] = \
                            np.asarray(prior_conf[var][1:], dtype=np.double)

                if 'Starts' in conf[counter_ref][counter_asc]:
                    mc.starting_point_flag = True
                    starts_conf = conf[counter_ref][counter_asc]['Starts']
                    for var in starts_conf:
                        mc.cov.starts[dataname_ref][dataname_asc]['correlation_' + var] = \
                            np.asarray(starts_conf[var], dtype=np.double)

    if 'Sinusoids' in config_in:
        conf = config_in['Sinusoids']
        mc.scv.Prot_bounds = np.asarray(conf['Prot'], dtype=np.double)
        if 'Priors' in conf:
            mc.scv.prior_kind[var] = conf['Priors'][var][0]
            mc.scv.prior_pams[var] = np.asarray(conf['Priors'][var][1:], dtype=np.double)

        for counter in conf['Seasons']:
            mc.scv.add_season_range(np.asarray(conf['Seasons'][counter][:2], dtype=np.double),
                                    conf['Seasons'][counter][2:])
>>>>>>> master

    for model in conf_models:
        if 'type' in conf_models[model]:
            mc.models[model] = define_type_to_class[conf_models[model]['type']](model)
        else:
            mc.models[model] = define_type_to_class[model](model)

        if mc.models[model].model_class is 'planets':
            conf = conf_models[model]
            for counter in conf:
                planet_name = 'Planet_' + repr(counter)
                planet_conf = conf[counter]

                print mc.models[model]
                mc.models[model].add_planet(planet_name)

                if 'orbit' in planet_conf:
                    # By default orbits are keplerians
                    if planet_conf['orbit'] == 'circular':
                        mc.models['planets'].switch_to_circular(planet_name)
                    if planet_conf['orbit'] == 'dynamical':
                        mc.models['planets'].switch_to_dynamical(planet_name)

                if 'transit' in planet_conf:
                    if planet_conf['transit']:
                        mc.models['planets'].switch_on_transit(planet_name)

                if 'inclination' in planet_conf:
                    mc.models['planets'].inclination[planet_name] = planet_conf['inclination']

                if 'radius' in planet_conf:
                    mc.models['planets'].radius[planet_name] = planet_conf['radius']

                boundaries_fixed_priors_stars(mc, model, planet_conf, planet_name)

        if mc.models[model].model_class is 'correlation':

            conf = conf_models[model]
            correlation_common = False

            """ When including the specific values for each dataset association, the existence of common variables must have
                been already checked, just to avoid problems to those distracted users that include the Common block after
                the dataset-specific ones
            """
            for counter_ref in conf:
                if counter_ref is 'common':
                    correlation_common = True

            for counter_ref in conf:
                if counter_ref is 'common' or counter_ref is 'type':
                    continue

                dataname_ref = mc.dataset_index[counter_ref]
                mc.models[model].add_dataset(dataname_ref)

                for counter_asc in conf[counter_ref]:
                    dataname_asc = mc.dataset_index[counter_asc]
                    mc.models[model].add_associated_dataset(mc, dataname_ref, dataname_asc)
                    free_zeropoint = False

                    """ Apply common settings (if present) 
                        before overriding them with the specific values (if provided)
                    """
                    if correlation_common:
                        common_conf = conf[counter_ref]['common']

                        """ The xero point of the correlation plot is already included as a free parameter
                         as the offset of the associated dataset, so it is disabled by default. However there may be 
                         situations in which it is still needed to have it as a free parameter, so this option is given"""

                        if 'free_zeropoint' not in common_conf or common_conf['Free_ZeroPoint'] is False:
                            mc.models[model].fix_list[dataname_ref][dataname_asc]['correlation_0'] = 0.0000
                            free_zeropoint = True

                        """ By default the origin of the x axis of the independent parameter (usually an activity indicator)
                        is set to the median value of the parameter. The user has te option to specify a value"""
                        if 'abscissa_zero' in common_conf:
                            mc.models[model].x_zero[dataname_ref][dataname_asc] = common_conf['abscissa_zero']

                        if 'order' in common_conf:
                            mc.models[model].order[dataname_ref][dataname_asc] = \
                                np.asarray(common_conf['order'], dtype=np.int64)

                        boundaries_fixed_priors_stars(mc, model, common_conf,
                                                      dataname_ref, dataname_asc, 'correlation_')

                    if free_zeropoint is False and \
                        ('free_zeropoint' not in conf[counter_ref][counter_asc] or
                         conf[counter_ref][counter_asc]['free_zeropoint'] is False):
                        mc.models[model].fix_list[dataname_ref][dataname_asc]['correlation_0'] = 0.0000

                    if 'abscissa_zero' in conf[counter_ref][counter_asc]:
                        mc.models[model].x_zero[dataname_ref][dataname_asc] = common_conf['abscissa_zero']

                    if 'order' in conf[counter_ref][counter_asc]:
                        mc.models[model].order[dataname_ref][dataname_asc] = \
                            np.asarray(conf[counter_ref][counter_asc]['order'], dtype=np.int64)

                    boundaries_fixed_priors_stars(mc, model, conf[counter_ref][counter_asc],
                                                  dataname_ref, dataname_asc, 'correlation_')

        if mc.models[model].model_class is 'gaussian_process':
            conf = conf_models[model]

            for name_ref in conf:
                if name_ref == 'type':
                    continue

                print name_ref
                if name_ref == 'common':
                    dataset_name = mc.models[model].common_ref
                else:
                    dataset_name = mc.dataset_index[name_ref]

                mc.models[model].add_dataset(dataset_name)

                boundaries_fixed_priors_stars(mc, model, conf[name_ref], dataset_name)

        if mc.models[model].model_class is 'curvature':

            conf = conf_models[model]

            if 'order' in conf:
                mc.models[model].order = np.asarray(conf['order'], dtype=np.int64)

            boundaries_fixed_priors_stars(mc, model, conf)

    if 'Tref' in conf_parameters:
        mc.Tref = np.asarray(conf_parameters['Tref'])
        for dataset_name in mc.dataset_dict:
            mc.dataset_dict[dataset_name].common_Tref(mc.Tref)

    if 'star_mass' in conf_parameters:
        mc.star_mass = np.asarray(conf_parameters['star_mass'][:], dtype=np.double)
    if 'star_radius' in config_in:
        mc.star_radius = np.asarray(conf_parameters['star_radius'][:], dtype=np.double)

    if 'dynamical_integrator' in conf_solver:
        mc.dynamical_model.dynamical_integrator = conf_parameters['dynamical_integrator']


                #if 'Sinusoids' in config_in:
    #    conf = config_in['Sinusoids']
    #    mc.scv.Prot_bounds = np.asarray(conf['Prot'], dtype=np.double)
    #    if 'Priors' in conf:
    #        mc.scv.prior_kind[var] = conf['Priors'][var][0]
    #        mc.scv.prior_pams[var] = np.asarray(conf['Priors'][var][1:], dtype=np.double)
    #
    #    for counter in conf['Seasons']:
    #        mc.scv.add_season_range(np.asarray(conf['Seasons'][counter][:2], dtype=np.double),
    #                                conf['Seasons'][counter][2:])

            # if 'Phase_dataset' in conf:
            #    # Additional activity indicators associated to RVs must the same order and number of sinusoids,
            #    #
            #    mc.scv.phase = np.asarray(conf['Phase_dataset'], dtype=np.int64)


    if 'pyde' in config_in:
        conf = config_in['pyde']

        if 'ngen' in conf:
            mc.pyde_parameters['ngen'] = np.asarray(conf['ngen'], dtype=np.double)

        if 'npop_mult' in conf:
            mc.pyde_parameters['npop_mult'] = np.asarray(conf['npop_mult'], dtype=np.int64)

    if 'emcee' in conf_solver:
        conf = conf_solver['emcee']

        if 'multirun' in conf:
            mc.emcee_parameters['multirun'] = np.asarray(conf['multirun'], dtype=np.int64)

        if 'MultiRun_iter' in conf:
            mc.emcee_parameters['multirun_iter'] = np.asarray(conf['multirun_iter'], dtype=np.int64)

        if 'nsave' in conf:
            mc.emcee_parameters['nsave'] = np.asarray(conf['nsave'], dtype=np.double)

        if 'nsteps' in conf:
            mc.emcee_parameters['nsteps'] = np.asarray(conf['nsteps'], dtype=np.int64)

        if 'nburn' in conf:
            mc.emcee_parameters['nburn'] = np.asarray(conf['nburn'], dtype=np.int64)

        if 'npop_mult' in conf:
            mc.emcee_parameters['npop_mult'] = np.asarray(conf['npop_mult'], dtype=np.int64)

        if 'thin' in conf:
            mc.emcee_parameters['thin'] = np.asarray(conf['thin'], dtype=np.int64)

    if 'polychord' in conf_solver:
        conf = conf_solver['polychord']

        if 'nlive' in conf:
            mc.polychord_parameters['nlive'] = np.asarray(conf['nlive'], dtype=np.int64)

        if 'nlive_mult' in conf:
            mc.polychord_parameters['nlive_mult'] = np.asarray(conf['nlive_mult'], dtype=np.int64)

        if 'num_repeats_mult' in conf:
            mc.polychord_parameters['num_repeats_mult'] = np.asarray(conf['num_repeats_mult'], dtype=np.int64)

        if 'feedback' in conf:
            mc.polychord_parameters['feedback'] = np.asarray(conf['feedback'], dtype=np.int64)

        if 'precision_criterion' in conf:
            mc.polychord_parameters['precision_criterion'] = np.asarray(conf['precision_criterion'], dtype=np.double)

        if 'max_ndead' in conf:
            mc.polychord_parameters['max_ndead'] = np.asarray(conf['max_ndead'], dtype=np.int64)

        if 'boost_posterior' in conf:
            mc.polychord_parameters['boost_posterior'] = np.asarray(conf['boost_posterior'], dtype=np.double)

        if 'read_resume' in conf:
            mc.polychord_parameters['read_resume'] = np.asarray(conf['read_resume'], dtype=bool)

        if 'base_dir' in conf:
            mc.polychord_parameters['base_dir'] = np.asarray(conf['base_dir'], dtype=str)

        #if 'file_root' in conf:
        #    mc.polychord_parameters['file_root'] = np.asarray(conf['file_root'], dtype=str)

        if 'shutdown_jitter' in conf:
            mc.polychord_parameters['shutdown_jitter'] = np.asarray(conf['shutdown_jitter'], dtype=bool)

    if 'recenter_bounds' in conf_solver:
        """ 
        required to avoid a small bug in the code
        if the dispersion of PyDE walkers around the median value is too broad,
        then emcee walkers will start outside the bounds, causing an error
        """
        mc.recenter_bounds_flag = conf_solver['recenter_bounds']


def boundaries_fixed_priors_stars(mc, model_name, conf, dataset_1=None, dataset_2=None, add_var_name =''):
    # type: (object, object, object, object, object, object) -> object

    if dataset_1 is None:
        if 'boundaries' in conf:
            bound_conf = conf['boundaries']
            for var in bound_conf:
                mc.models[model_name].bounds[add_var_name+var] = np.asarray(bound_conf[var], dtype=np.double)

        if 'fixed' in conf:
            fixed_conf = conf['fixed']
            for var in fixed_conf:
                mc.models[model_name].fix_list[add_var_name+var] = np.asarray(fixed_conf[var], dtype=np.double)

        if 'priors' in conf:
            prior_conf = conf['priors']
            for var in prior_conf:
                mc.models[model_name].prior_kind[add_var_name+var] = prior_conf[var][0]
                mc.models[model_name].prior_pams[add_var_name+var] = np.asarray(prior_conf[var][1:], dtype=np.double)

        if 'starts' in conf:
            mc.starting_point_flag = True
            starts_conf = conf['starts']
            for var in starts_conf:
                mc.models[model_name].starts[add_var_name+var] = np.asarray(starts_conf[var], dtype=np.double)

    elif dataset_2 is None:
        if 'boundaries' in conf:
            bound_conf = conf['boundaries']
            for var in bound_conf:
                mc.models[model_name].bounds[dataset_1][add_var_name+var] = np.asarray(bound_conf[var], dtype=np.double)

        if 'fixed' in conf:
            fixed_conf = conf['fixed']
            for var in fixed_conf:
                mc.models[model_name].fix_list[dataset_1][add_var_name+var] = np.asarray(fixed_conf[var], dtype=np.double)

        if 'priors' in conf:
            prior_conf = conf['priors']
            for var in prior_conf:
                mc.models[model_name].prior_kind[dataset_1][add_var_name+var] = prior_conf[var][0]
                mc.models[model_name].prior_pams[dataset_1][add_var_name+var] = np.asarray(prior_conf[var][1:], dtype=np.double)

        if 'starts' in conf:
            mc.starting_point_flag = True
            starts_conf = conf['starts']
            for var in starts_conf:
                mc.models[model_name].starts[dataset_1][add_var_name+var] = np.asarray(starts_conf[var], dtype=np.double)

    else:

        if 'boundaries' in conf:
            bound_conf = conf['boundaries']
            for var in bound_conf:
                mc.models[model_name].bounds[dataset_1][dataset_2][add_var_name + var] = \
                    np.asarray(bound_conf[var], dtype=np.double)

        if 'fixed' in conf:
            fixed_conf = conf['fixed']
            for var in fixed_conf:
                mc.models[model_name].fix_list[dataset_1][dataset_2][add_var_name + var] = \
                    np.asarray(fixed_conf[var], dtype=np.double)

        if 'priors' in conf:
            prior_conf = conf['priors']
            for var in prior_conf:
                mc.models[model_name].prior_kind[dataset_1][dataset_2][add_var_name + var] = prior_conf[var][0]
                mc.models[model_name].prior_pams[dataset_1][dataset_2][add_var_name + var] = \
                    np.asarray(prior_conf[var][1:], dtype=np.double)

        if 'starts' in conf:
            mc.starting_point_flag = True
            starts_conf = conf['starts']
            for var in starts_conf:
                mc.models[model_name].starts[dataset_1][dataset_2][add_var_name + var] = \
                    np.asarray(starts_conf[var], dtype=np.double)

    return