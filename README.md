# scheduler-model

Information about the project can be found [in the report here](https://apps.cs.utexas.edu/apps/sites/default/files/tech_reports/load_balance_cx_synthesis.pdf).
This repository contains code to model the scheduler using Rosette,
and we use Rosette's synthesis features to generate counterexamples to performance invariants
for the scheduler.

## Usage

This code was developed with Racket v8.17.
Also,
ensure that Rosette is installed
by running `raco pkg install rosette`.

To run the solver,
run `racket src/runner.rkt <json-file>`.
The JSON files used by the solver
can be generated using the `munch` subsystem in [this fork of the kernel](https://github.com/fishy15/linux-cfs-testing),
and it is just a list of multiple instances of load balancing,
with the information used by the kernel specified
or `'null` if that information was never observed.
[This CloudLab profile](https://github.com/fishy15/cfs-testing-cloudlab-profile)
helps set up the environment for collecting data from the kernel.

To run against a single invariant,
run `racket src/runner.rkt <json-file> <invariant-name>`,
where the name is specified in `./src/checker/invariants.rkt`.
By default,
the solver runs against every invariant.

The solver will first check that the consistency checks are indeed consistent.
It might be possible to add consistency checks that accidentally contradict each other,
which means that no possible hidden state could be generated
that satisfies all the consisitency checks.
if this is the case,
it will print `INCONSISTENCY FOUND`,
along with the a minimal subset of consistency checks
that are inconsistent with each other
and a JSON output with the visible state it failed on.
On commit `2f74ca5`,
running `racket src/runner.rkt 16-example.json moves-from-busiest` will produce the output:

```
INCONSISTENCY FOUND
CHECKS: (#<procedure:group-utils-matches-visible> #<procedure:tasks-iff-positive-util> #<procedure:group-tasks-matches-visible>)
VISIBLE: {
  "per-sd-info": [
    {
      "sd": {
        "dst-cpu": 0,
        "cpumask": "1111111111111111",
...
```

If it passes the initial consistency check,
it then tries to synthesize a hidden state
that is consistent with all the consistency checks
but breaks some invariant.
This can either output
`PASSED`,
which means that no counterexamples were found;
or `FOUND COUNTEREXAMPLE`,
which prints the visible state and the generated hidden state
that produced a counterexample.

### Benchmarking

To measure the performance solving against specific invariants,
run `racket ./src/runner.rkt <json-file> <invariant-name> bench`.
This skips the initial inconsistency check
and prints out the total time taken and the number of examples in the file.

`run.go` and `summarize.py` are tools using this to collect data.
`run.go` assumes that example files are placed in the `./data` directory
with the file format `<topology>-<task-name>.json`.
The list of topologies and list of invariants to test
are specified in `run.go`.
The information is then collected and stored
in a file for each invariant separately.

`summarize.py` can then be used to compute statistics based on the information in the file.
Both `run.go` and `summarize.py` were written with a specific use-case in mind,
so they should be modified for other cases or written to be more general
in the future.

## Implementation

### ./src/visible/

This directory represents the "visible" state of the scheduler,
which corresponds to the data directly used by the scheduler
to make its decision.
Its structure was manually created
by manually reading the scheduler functions in [`kernel/sched/fair.c`](https://github.com/fishy15/linux-cfs-testing/blob/master/kernel/sched/fair.c).
Whenever the kernel accessed a new value,
a corresponding variable was created in `./src/visible/state.rkt`
to hold its value
and a line was added to `./src/visible/reader.rkt`
to retrieve the value from the JSON object.

TODO: is it possible to automatically do this process, maybe with some configuration file
that updates both the Rosette and Rust code in the kernel?

In a single load balance pass,
the kernel loops through the scheduler domains
and load balances on each of them individually.
For this reason,
two types of information are stored:
`per-sd-info`,
which is information related to the current scheduler domain in the pass,
and `per-cpu-info`,
which is information tied to a specified CPU.
The `per-sd-info` is further divided into information about the scheduler domain overall (`sd`),
or information about the CPU groups in the scheduler domain (`groups`).
More details about the structure can be found in `./src/visible/state.rkt`.

### ./src/hidden/

This directory represents the "hidden" state of the scheduler,
which corresponds to the total information about the system,
even if it was not directly observed.
The goal of the project is to synthesize some hidden state
that is consistent with the visible state
but violates some performance invariant.
More details about this specifically are present in the report above.

The variables we picked in the hidden state
are simply the variables that we created in our performance invariants.
New variables can easily be added to the state (or removed if not needed anymore).

### ./src/checker/

There are two types of checks:
- consistency checks (in `./src/checker/consistency.rkt`),
  which ensure that the generated hidden state is possible given the visible state.
  For example,
  if some value is directly observed in the visible state,
  it must have that value in the hidden state.
- performance invariants (in `./src/checker/invariants.rkt`),
  which checks that the decision the scheduler makes
  satisfies formally-specified performance requirements.
  One possible such requirement is: if there is an overloaded CPU and an idle CPU,
  then a task is moved from the overloaded CPU to the idle CPU.