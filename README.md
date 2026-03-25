# ansible_jmeter_scripts

Small Ansible playbooks and helper scripts for preparing a `testbots` host group used for JMeter-style load test workers.

The repository currently focuses on four operational tasks:

- setting a hostname derived from the machine's current hostname
- copying a hosts file to remote machines
- raising file/process limits and reloading `sysctl`
- installing `dstat`

## Repository contents

- `testbots.yml`: copies `sethostname.sh` to remote hosts and runs it
- `testbots_hostfile.yml`: copies a hosts file to remote hosts and prints the end of `/etc/hosts`
- `testbots_limits.yml`: copies `setlimits.sh` to remote hosts and runs it
- `start_dstat.yml`: installs `dstat` and checks that it is present
- `sethostname.sh`: rewrites `/etc/hostname` and reboots the host
- `setlimits.sh`: appends kernel and user limit settings, reloads `sysctl`, and reboots the host

## Requirements

- Ansible installed on the control machine
- an inventory containing a `testbots` group
- root access on target machines, or an Ansible configuration that uses privilege escalation
- Debian/Ubuntu targets for `start_dstat.yml`, because it uses the `apt` module

## Important behavior

These playbooks make privileged system changes. Two of them reboot the remote host after applying changes.

- `testbots.yml` reboots each target after writing `/etc/hostname`
- `testbots_limits.yml` reboots each target after appending to `/etc/security/limits.conf`
- `testbots_hostfile.yml` overwrites `/etc/hosts` on the target

Review the scripts before running them in production or against shared systems.

## Usage

Example inventory:

```ini
[testbots]
testbot-01
testbot-02
```

Run a playbook with an explicit inventory:

```bash
ansible-playbook -i inventory.ini testbots.yml
ansible-playbook -i inventory.ini testbots_hostfile.yml
ansible-playbook -i inventory.ini testbots_limits.yml
ansible-playbook -i inventory.ini start_dstat.yml
```

If your Ansible user is not root, use privilege escalation:

```bash
ansible-playbook -i inventory.ini -b testbots.yml
```

## Controller-side file expectations

The current playbooks use absolute `copy.src` paths:

- `testbots.yml` expects `/etc/ansible/sethostname.sh` on the control machine
- `testbots_limits.yml` expects `/etc/ansible/setlimits.sh` on the control machine
- `testbots_hostfile.yml` expects `/etc/hosts` on the control machine

That means the repository files are not used directly unless you copy them into those locations or update the playbooks to reference the checked-in files.

## Operational notes

### `sethostname.sh`

The script derives the new hostname from the fifth `-` separated field of the current hostname and rewrites `/etc/hostname` as:

```text
testbot<suffix>
```

Example:

- current hostname: `qa-load-east-node-12`
- derived suffix: `12`
- new hostname: `testbot12`

If the current hostname does not match that format, the resulting hostname may be empty or malformed.

### `setlimits.sh`

The script appends the following changes every time it runs:

- `fs.file-max = 65536` in `/etc/sysctl.conf`
- soft and hard `nproc` limits of `65535`
- soft and hard `nofile` limits of `65535`

Because the values are appended rather than managed idempotently, repeated runs will duplicate entries in the target configuration files.

## Current review notes

These are the main issues visible from the current code:

1. The playbooks depend on controller-local absolute paths instead of repository-relative files. Fresh clones will not run without extra setup. Relevant lines: `testbots.yml:7`, `testbots_limits.yml:7`, `testbots_hostfile.yml:7`.
2. `setlimits.sh` is not idempotent and will append duplicate configuration on every run. Relevant lines: `setlimits.sh:3-10`.
3. `start_dstat.yml` installs with `apt` but verifies with `rpm`, which is inconsistent for Debian-based systems and will fail on hosts without the RPM toolchain. Relevant lines: `start_dstat.yml:7-10`.
4. `sethostname.sh` assumes a hostname structure with at least five `-` separated fields, but there is no validation before rebooting the machine. Relevant lines: `sethostname.sh:3-12`.

## Validation performed

- `shellcheck sethostname.sh`
- `shellcheck setlimits.sh`

`ansible-playbook` syntax checks were not run in this workspace because Ansible is not installed here.
