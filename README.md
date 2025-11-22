# Workspace setup

The project provides a quick setup installation based on environment and profile.

To install:

```sh
./install.sh --env <environment> --profile <profile>
```

> **Note**
>
> Check available environments and profiles run `./install.sh --help`

## Testing 
To install locally, and to see how the workspace will be setup, run `./test.sh` and check the newly created `./install/` directory.

Then `.bashrc` can be sourced in the current shell session:

```sh
HOME=$PWD/install/home source ./install/home/.bashrc
```