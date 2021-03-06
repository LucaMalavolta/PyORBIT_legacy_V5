import pyorbit
import argparse

if __name__ == '__main__':
    print 'This program is being run by itself'

    parser = argparse.ArgumentParser(prog='PyORBIT_GetResults.py', description='PyDE+emcee runner')
    parser.add_argument('sampler', type=str, nargs=1, help='sampler (emcee or polychord)')
    parser.add_argument('config_file', type=str, nargs=1, help='config file')
    parser.add_argument('-p', type=str, nargs='?', default=False, help='Plot model files')
    parser.add_argument('-w', type=str, nargs='?', default=False, help='Write model files')
    parser.add_argument('-c', type=str, nargs='?', default=False, help='Create chains plots')
    parser.add_argument('-ln', type=str, nargs='?', default=False, help='Create ln_prob chain plot')
    parser.add_argument('-t', type=str, nargs='?', default=False, help='Create Gelman-Rubin traces')
    parser.add_argument('-fc', type=str, nargs='?', default=False, help='Create full corellation plot - it may be slow!')
    parser.add_argument('-cc', type=str, nargs='?', default=False, help='Create corner plots of common variables')
    parser.add_argument('-dc', type=str, nargs='?', default=False, help='Create individual corner plots of reach dataset')
    parser.add_argument('-all_corners', type=str, nargs='?', default=False, help='Do all the corner plots')
    parser.add_argument('-all', type=str, nargs='?', default=False, help='Active all flags')

    plot_dictionary = {
        'plot_models': False,
        'write_models': False,
        'chains': False,
        'traces': False,
        'lnprob_chain': False,
        'full_correlation': False,
        'dataset_corner': False,
        'common_corner': False
    }

    args = parser.parse_args()
    sampler = args.sampler[0]
    file_conf = args.config_file[0]

    if args.p is not False :
        plot_dictionary['plot_models'] = True
    if args.w is not False:
        plot_dictionary['write_models'] = True
    if args.c is not False :
        plot_dictionary['chains'] = True
    if args.t is not False:
        plot_dictionary['traces'] = True
    if args.fc is not False:
        plot_dictionary['lnprob_chain'] = True
    if args.fc is not False:
        plot_dictionary['full_correlation'] = True
    if args.dc is not False:
        plot_dictionary['dataset_corner'] = True
    if args.cc is not False:
        plot_dictionary['common_corner'] = True

    if args.all is not False:
        plot_dictionary['plot_models'] = True
        plot_dictionary['write_models'] = True
        plot_dictionary['lnprob_chain'] = True
        plot_dictionary['chains'] = True
        plot_dictionary['traces'] = True
        plot_dictionary['full_correlation'] = True
        plot_dictionary['common_corner'] = True
        plot_dictionary['dataset_corner'] = True

    if args.all_corners is not False:
        plot_dictionary['full_correlation'] = True
        plot_dictionary['common_corner'] = True
        plot_dictionary['dataset_corner'] = True

    print plot_dictionary
    config_in = pyorbit.yaml_parser(file_conf)

    pyorbit.pyorbit_getresults(config_in, sampler, plot_dictionary)