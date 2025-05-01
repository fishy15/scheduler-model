import sys
from collections import defaultdict

class TimingInfo:
    sum_cpu: int
    sum_real: int
    num_examples: int

    def __init__(self):
        self.sum_cpu = 0
        self.sum_real = 0
        self.num_examples = 0

    def add(self, cpu: int, real: int, exs: int):
        self.sum_cpu += cpu
        self.sum_real += real
        self.num_examples += exs

    def avg_cpu(self) -> float:
        return self.sum_cpu / self.num_examples

    def avg_real(self) -> float:
        return self.sum_real / self.num_examples

def get_topology(filename) -> str:
    comps = filename.split('-')
    if comps[1] == 'tiered':
        return comps[0] + '-tiered'
    return comps[0]

def get_times(times) -> tuple[int, int]:
    comps = times.split()
    return int(comps[2]), int(comps[5])

def process_data(lines: list[str]):
    data: defaultdict[str, TimingInfo] = defaultdict(TimingInfo)

    for i in range(0, len(lines), 5):
        info = lines[i]
        times = lines[i+2]

        filename = info.split()[2]
        topology = get_topology(filename)
        cpu_time, real_time = get_times(times)
        examples = int(lines[i+3])

        data[topology].add(cpu_time, real_time, examples)

    for top, timing in data.items():
        print(top, 'cpu:', timing.avg_cpu(), 'real:', timing.avg_real())

def main():
    try:
        filename = sys.argv[1]
    except IndexError:
        print('file name needed')
        return

    with open(filename, 'r') as f:
        data = [l.strip() for l in f.readlines() if len(l.strip()) > 0]
        process_data(data)

if __name__ == '__main__':
    main()
