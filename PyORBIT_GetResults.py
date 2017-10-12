import pyorbit
import argparse

if __name__ == '__main__':
    print 'This program is being run by itself'

    parser = argparse.ArgumentParser(prog='PyORBIT_GetResults.py', description='PyDE+emcee runner')
    parser.add_argument('sample', type=str, nargs=1, help='sample (emcee or polychord)')
    parser.add_argument('config_file', type=str, nargs=1, help='config file')
    parser.add_argument('-p', type=str, nargs='?', default=False, help='Create plot files')
    parser.add_argument('-c', type=str, nargs='?', default=False, help='Create chains plots')
    parser.add_argument('-t', type=str, nargs='?', default=False, help='Create Gelman-Rubin traces')
    parser.add_argument('-m', type=str, nargs='?', default=False, help='Create full corellation plot - it may be slow!')

    plot_dictionary = {
        'chains': False,
        'plot': False,
        'traces': False,
        'full_correlation': False
    }

    args = parser.parse_args()
    sampler = args.sample[0]
    file_conf = args.config_file[0]

    if args.p is not False :
        plot_dictionary['plot'] = True
    if args.c is not False :
        plot_dictionary['chains'] = True
    if args.t is not False:
        plot_dictionary['traces'] = True
    if args.m is not False:
        plot_dictionary['full_correlation'] = True

    print plot_dictionary
    config_in = pyorbit.yaml_parser(file_conf)

    pyorbit.pyorbit_getresults(config_in, sampler, plot_dictionary)