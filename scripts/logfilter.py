import re

def filter_logs(input_file, output_file):
    # Define regular expression pattern to match the desired log line format
    pattern = re.compile(r'\d+/\d+ VUs, \d+ complete and \d+ interrupted iterations')

    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        for line in infile:
            if pattern.search(line):
                outfile.write(line)

if __name__ == "__main__":
    input_file = "LogReceipt.txt"  # Specify the path to your input log file
    output_file = "FilteredLogReceipt.txt"  # Specify the path for the output filtered log file

    filter_logs(input_file, output_file)