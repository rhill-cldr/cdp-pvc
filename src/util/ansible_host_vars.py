import argparse
import json
import logging
import os
from pyhocon import ConfigFactory
from argparse import ArgumentParser


logging.basicConfig(level=os.environ.get("LOGLEVEL", "INFO"))


def load_conf() -> ConfigFactory:
    conf = ConfigFactory.parse_file("runner/inventory/hosts.conf")
    return conf


def create_parser(conf: ConfigFactory) -> ArgumentParser:
    parser = ArgumentParser(description='Handle Ansible dynamic inventory --host <hostname> call.')
    parser.add_argument('host_args', metavar='N', type=str, nargs='+',
                        help='args passed to invientory script')
    return parser


if __name__ == "__main__":
    log = logging.getLogger(__name__)
    conf = load_conf()
    parser = create_parser(conf)
    args = parser.parse_args()
    log.debug(args.host_args)
    print(json.dumps({}))

