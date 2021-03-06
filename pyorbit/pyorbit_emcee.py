from classes.common import *
from classes.model_container_emcee import ModelContainerEmcee
from classes.input_parser import yaml_parser, pars_input
from classes.io_subroutines import pyde_save_to_pickle, pyde_load_from_cpickle, \
    emcee_save_to_cpickle, emcee_load_from_cpickle, emcee_flatchain, emcee_create_dummy_file
import emcee
import os
import sys

__all__ = ["pyorbit_emcee", "yaml_parser"]


def pyorbit_emcee(config_in, input_datasets=None, return_output=None):

    pyde_dir_output = './' + config_in['output'] + '/pyde/'
    emcee_dir_output = './' + config_in['output'] + '/emcee/'

    reloaded_pyde = False
    reloaded_emcee_multirun = False
    reloaded_emcee = False


    try:
        mc, population, starting_point = pyde_load_from_cpickle(pyde_dir_output, prefix='')
        reloaded_pyde = True
    except:
        pass

    try:
        mc, starting_point, population, _, _, sampler_chain, _, _ = \
            emcee_load_from_cpickle(emcee_dir_output, prefix='MR')
        reloaded_emcee_multirun = True
    except:
        pass

    try:
        mc, starting_point, population, _, _, sampler_chain, sampler_lnprobability, _ = \
            emcee_load_from_cpickle(emcee_dir_output)
        reloaded_emcee = True
    except:
        pass

    print
    print 'reloaded_pyde: ', reloaded_pyde
    print 'reloaded_emcee_multirun: ', reloaded_emcee_multirun
    print 'reloaded_emcee: ', reloaded_emcee

    if reloaded_emcee:
        """ There's no need to do anything"""
        flatchain = emcee_flatchain(sampler_chain, mc.emcee_parameters['nburn'], mc.emcee_parameters['thin'])
        mc.model_setup()
        mc.initialize_logchi2()
        mc.results_resumen(flatchain)

        print
        print mc.star_mass
        print mc.common_models
        print

        if return_output:
            return mc, sampler_chain, sampler_lnprobability
        else:
            return

    reloaded_mc = reloaded_pyde or reloaded_emcee_multirun or reloaded_emcee_multirun

    if not reloaded_mc:
        mc = ModelContainerEmcee()

        pars_input(config_in, mc, input_datasets)

        if mc.pyde_parameters['shutdown_jitter'] or mc.emcee_parameters['shutdown_jitter']:
            for dataset in mc.dataset_dict.itervalues():
                dataset.shutdown_jitter()

        # keep track of which version has been used to perform emcee computations
        mc.emcee_parameters['version'] = emcee.__version__[0]

        mc.model_setup()
        mc.create_variables_bounds()
        mc.initialize_logchi2()

        mc.results_resumen(None, skip_theta=True)

        mc.pyde_dir_output = pyde_dir_output
        mc.emcee_dir_output = emcee_dir_output

        mc.emcee_parameters['nwalkers'] = mc.ndim * mc.emcee_parameters['npop_mult']
        if mc.emcee_parameters['nwalkers']%2 == 1: mc.emcee_parameters['nwalkers'] += 1

        #if mc.dynamical_model is not None:
        #    mc.dynamical_model.prepare(mc)
    else:
        mc.pyde_dir_output = pyde_dir_output
        mc.emcee_dir_output = emcee_dir_output

        """ reload nsteps, burnin and other parameters for emcee"""
        pars_input(config_in, mc, input_datasets, reload_emcee=True)

        mc.model_setup()
        mc.initialize_logchi2()

    if not os.path.exists(mc.emcee_dir_output):
        os.makedirs(mc.emcee_dir_output)

    if not hasattr(mc, 'use_threading_pool'):
        mc.use_threading_pool = False

    emcee_version = mc.emcee_parameters['version'][0]

    print
    print 'Include priors: ', mc.include_priors
    print
    print 'Reference Time Tref: ', mc.Tref
    print
    print 'Dimensions = ', mc.ndim
    print 'Nwalkers = ', mc.emcee_parameters['nwalkers']
    print
    print '*************************************************************'
    print

    if mc.starting_point_flag:
        mc.create_starting_point()
        starting_point = mc.starting_point
        population = np.zeros([mc.emcee_parameters['nwalkers'], mc.ndim], dtype=np.double)
        for ii in xrange(0, mc.emcee_parameters['nwalkers']):
            population[ii, :] = np.random.normal(starting_point, 0.0000001)
        reloaded_pyde = True

        print 'PyDE reloaded'
        sys.stdout.flush()

    if not reloaded_pyde:
        if not os.path.exists(mc.pyde_dir_output):
            os.makedirs(mc.pyde_dir_output)

        print 'PyDE running'
        sys.stdout.flush()

        de = DiffEvol(mc, mc.bounds, mc.emcee_parameters['nwalkers'], maximize=True)
        de.optimize(mc.pyde_parameters['ngen'])

        population = de.population
        starting_point = np.median(population, axis=0)

        #np.savetxt(mc.pyde_dir_output + 'pyDEout_original_bounds.dat', mc.bounds)
        #np.savetxt(mc.pyde_dir_output + 'pyDEout_original_pops.dat', population)

        """ bounds redefinition and fix for PyDE anomalous results """
        if mc.recenter_bounds_flag:
            pyde_save_to_pickle(mc, population, starting_point, prefix='orig')

            mc.recenter_bounds(starting_point)
            population = mc.fix_population(starting_point, population)
            starting_point = np.median(population, axis=0)

            print 'Boundaries redefined after PyDE output'

        pyde_save_to_pickle(mc, population, starting_point)

        print 'PyDE completed'
        sys.stdout.flush()

    mc.results_resumen(starting_point, compute_lnprob=True)

    if mc.use_threading_pool:
        if emcee_version =='2':
            threads_pool = emcee.interruptible_pool.InterruptiblePool(mc.emcee_parameters['nwalkers'])
        else:
            from multiprocessing.pool import Pool as InterruptiblePool
            threads_pool = InterruptiblePool(mc.emcee_parameters['nwalkers'])

    if mc.emcee_parameters['multirun'] and not reloaded_emcee_multirun:

        for ii in xrange(0, mc.emcee_parameters['multirun_iter']):
            print 'emcee exploratory run #', ii, ' of ', mc.emcee_parameters['multirun_iter']
            # sampler = emcee.EnsembleSampler(mc.emcee_parameters['nwalkers'], mc.ndim, mc,
            #                                 threads=mc.emcee_parameters['nwalkers'])
            if mc.use_threading_pool:
                sampler = emcee.EnsembleSampler(mc.emcee_parameters['nwalkers'], mc.ndim, mc, pool=threads_pool)
            else:
                sampler = emcee.EnsembleSampler(mc.emcee_parameters['nwalkers'], mc.ndim, mc)

            population, prob, state = sampler.run_mcmc(population, mc.emcee_parameters['multirun'])
            flatchain = emcee_flatchain(sampler.chain, mc.emcee_parameters['nburn'], mc.emcee_parameters['thin'])
            mc.results_resumen(flatchain)

            max_ind = np.argmax(prob)
            starting_point = population[max_ind, :]
            population = np.asarray([starting_point + 1e-4*np.random.randn(mc.ndim) for i in range(mc.emcee_parameters['nwalkers'])])
            sampler.reset()

            emcee_save_to_cpickle(mc, starting_point, population, prob, state, sampler, prefix='MR_'+repr(ii))

        emcee_save_to_cpickle(mc, starting_point, population, prob, state, sampler, prefix='MR')

        flatchain = emcee_flatchain(sampler.chain, mc.emcee_parameters['nburn'], mc.emcee_parameters['thin'])
        mc.results_resumen(flatchain)

        print 'emcee exploratory runs completed'
        sys.stdout.flush()

    print 'emcee'
    state = None

    if mc.use_threading_pool:
        sampler = emcee.EnsembleSampler(mc.emcee_parameters['nwalkers'], mc.ndim, mc, pool=threads_pool)
    else:
        sampler = emcee.EnsembleSampler(mc.emcee_parameters['nwalkers'], mc.ndim, mc)

    if mc.emcee_parameters['nsave'] > 0:
        print ' Saving temporary steps'
        niter = int(mc.emcee_parameters['nsteps']/mc.emcee_parameters['nsave'])
        sampled = 0
        for i in xrange(0, niter):
            population, prob, state = sampler.run_mcmc(population, mc.emcee_parameters['nsave'], thin=mc.emcee_parameters['thin'], rstate0=state)
            sampled += mc.emcee_parameters['nsave']
            emcee_save_to_cpickle(mc, starting_point, population, prob, state, sampler, samples=sampled)

            flatchain = emcee_flatchain(sampler.chain, mc.emcee_parameters['nburn'], mc.emcee_parameters['thin'])
            mc.results_resumen(flatchain)

            print sampled, '  steps completed, average lnprob:, ', np.median(prob)
            sys.stdout.flush()

    else:
        population, prob, state = sampler.run_mcmc(population, mc.emcee_parameters['nsteps'], thin=mc.emcee_parameters['thin'])

        emcee_save_to_cpickle(mc, starting_point, population, prob, state, sampler)

        flatchain = emcee_flatchain(sampler.chain, mc.emcee_parameters['nburn'], mc.emcee_parameters['thin'])
        mc.results_resumen(flatchain)

    print 'emcee completed'

    if mc.use_threading_pool:
        # close the pool of threads
        threads_pool.close()
        threads_pool.terminate()
        threads_pool.join()

    """ A dummy file is created to let the cpulimit script to proceed with the next step"""
    emcee_create_dummy_file(mc)

    if return_output:
        return mc, sampler.chain,  sampler.lnprobability

