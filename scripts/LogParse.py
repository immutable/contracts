import re

def parse_log_file(file_path):
    durations = []
    with open(file_path, 'r') as file:
        for line in file:
            match = re.search(r'TIME\(ms\) => (\d+)', line)
            if match:
                durations.append(int(match.group(1)))
    return durations

def calculate_average(durations):
    if durations:
        return sum(durations) / len(durations)
    else:
        return 0

if __name__ == "__main__":
    log_file_path = "./0_run_3.txt"  # Replace this with the path to your log file
    durations = parse_log_file(log_file_path)
    average_time = calculate_average(durations)
    print("Average time:", average_time)