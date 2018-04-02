#!/usr/bin/python
# -*- coding: utf-8 -*-
# Copyright (c) 2015 Amir Mofasser <amir.mofasser@gmail.com> (@amimof)

# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
DOCUMENTATION = """
module: wsadmin
version_added: "1.0.3"
author: "Yuriy Rumyantsev (SBT-Rumyantsev-YUN@mail.ca.sbrf.ru)"
"""

EXAMPLES = """
# Run:
"""
import os
import subprocess
import platform
import datetime
import random
import string

def random_generator(size, chars=string.ascii_letters + string.digits):
    return ''.join(random.choice(chars) for _ in range(size))

def main():

    # Read arguments
    module = AnsibleModule(
        argument_spec = dict(
            wasdir = dict(default='', required=False),
            washost = dict(default='', required=False),
            wasport = dict(default='', required=False),
            conntype = dict(default='', required=False),
            lang = dict(default='', required=False),
            was_params = dict(default='', required=False),
            tracefile = dict(default='', required=False),
            username = dict(default='', required=False),
            password = dict(default='', required=False, no_log=True),
            script = dict(default='', required=False),
            script_params = dict(default='', required=False),
            was_command = dict(default='', required=False),
            accept_cert = dict(default=False, required=False)
        )
    )

    wasdir = module.params['wasdir']
    washost = module.params['washost']
    wasport = module.params['wasport']
    conntype = module.params['conntype']
    lang = module.params['lang']
    was_params = module.params['was_params']
    tracefile = module.params['tracefile']
    username = module.params['username']
    d = str(random_generator(5))
    os.environ[d] = module.params['password']
    script = module.params['script']
    script_params = module.params['script_params']
    was_command = module.params['was_command']
    accept_cert = module.params['accept_cert']
    if os.environ[d]:
        new_password = " -password $" + d + " "
    else:
        new_password = ""
    argument = ""
    if script != "" and was_command != "":
        module.fail_json(msg="Use only  one parameter script or command")
    else:
        argument = ""
        if script != "":
            argument = " -f " + script + script_params
        if was_command != "":
            argument = " -c " + was_command
    username = " -username " + username + " " if username != "" else username
    conntype = " -conntype " + conntype + " " if conntype != "" else conntype
    lang = " -lang " + lang + " " if lang != "" else " -lang jython "
    washost = " -host  " + washost + " " if washost != "" else washost
    wasport = " -port " + wasport + " " if wasport != "" else wasport
    tracefile = " -tracefile " + tracefile + " " if tracefile != "" else tracefile
    if accept_cert.upper() is not True:
        if new_password != "":
            raw_command_line = os.path.join(wasdir,'wsadmin.sh')+" " + lang + conntype + washost + wasport + was_params + username + new_password + tracefile + argument
        else:
            raw_command_line = os.path.join(wasdir,'wsadmin.sh')+" " + lang + conntype + washost + wasport + was_params + username + tracefile + argument
    else:
        raw_command_line = "echo y| " + os.path.join(wasdir,'wsadmin.sh')+" "  + lang + conntype + washost + wasport + was_params + argument

    if wasdir:
        wasdir = os.path.abspath(wasdir)
        os.chdir(wasdir)

    child = subprocess.Popen(
        [raw_command_line],
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    stdout_value, stderr_value = child.communicate()

    if child.returncode != 0:
        if script != "" and accept_cert is not True:
            module.fail_json(
                changed=False,
                msg="Failed executing wsadmin script:  {0} ".format(script),
                stdout=stdout_value,
                stderr=stderr_value
            )
        elif was_command != "" and accept_cert is not True:
            module.fail_json(
                changed=False,
                msg="Failed executing wsadmin command:  {0} ".format(was_command),
                stdout=stdout_value,
                stderr=stderr_value
            )
        elif accept_cert is True:
            module.fail_json(
                changed=True,
                msg="Failed  accept certificate wsadmin ".format(),
                stdout=stdout_value,
                stderr=stderr_value)
    else:
        if script != "" and accept_cert is not True:
            module.exit_json(
                changed=True,
                msg="Script executed successfully: {0}".format(script),
                stdout=stdout_value,
                stderr=stderr_value,
            )
        elif was_command != "" and accept_cert is not True:
            module.fail_json(
                changed=True,
                msg="Wsadmin command executed successfully:  {0} ".format(was_command),
                stdout=stdout_value,
                stderr=stderr_value
            )
        elif accept_cert is True:
            module.fail_json(
                changed=True,
                msg="Wsadmin accept certificate successfully ".format(),
                stdout=stdout_value,
                stderr=stderr_value)


# import module snippets
from ansible.module_utils.basic import *
if __name__ == '__main__':
    main()
