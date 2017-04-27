#!/usr/bin/env python


try:
    import json
except ImportError:
    import simplejson as json
import os
import sys
from optparse import OptionParser

def get_variables(host, options):
    vars = options[host]
    return vars.get('variables', {})


def main_list(options, config_path):
    results = {
        'all': {
            'hosts': [],
        },
        '_meta': {
            'hostvars': {},
        }
    }

    with open(config_path) as data_file:
        data = json.load(data_file)

    for h, op in data.items():
        results['all']['hosts'].append(h)
        vars = get_variables(h, data)
        vars.update({
            "ansible_port": op['port'],
            "ansible_host": op['host'],
        })
        results['_meta']['hostvars'][h] = vars

    return results


def main_host(options, config_path):
    with open(config_path) as data_file:
        data = json.load(data_file)
    return get_variables(options.host, data)


def main():
    config_path = os.path.join(
        os.path.dirname(os.path.abspath(__file__)),
        os.path.splitext(os.path.basename(__file__))[0] + ".json"
    )

    parser = OptionParser(usage='%prog [options] --list | --host HOSTNAME')
    parser.add_option('--list', action="store_true", default=False, dest="list")
    parser.add_option('--host', dest="host")
    parser.add_option('--pretty', action="store_true", default=False, dest='pretty')
    (options, args) = parser.parse_args()

    if options.list:
        data = main_list(options, config_path)
    elif options.host:
        data = main_host(options, config_path)
    else:
        parser.print_help()
        sys.exit(1)

    indent = None
    if options.pretty:
        indent = 2

    print(json.dumps(data, indent=indent))


if __name__ == '__main__':
    main()

