import sys
import subprocess
import pkg_resources

def main():
    if len(sys.argv) < 2:
        print("Usage: mKmer <command> [arguments]")
        sys.exit(1)
    command = sys.argv[1]
    script_mapping = {
        "KmerCell": pkg_resources.resource_filename('mKmer.KmerCell', 'KmerCell.py'),
        "KmerFrequency": pkg_resources.resource_filename('mKmer.KmerFrequency', 'KmerFrequency.py'),
        "KmerGOn": pkg_resources.resource_filename('mKmer.KmerGOn', 'KmerGOn.py'),
        "KmerGOp": pkg_resources.resource_filename('mKmer.KmerGOp', 'KmerGOp.py'),
        "KmerRank": pkg_resources.resource_filename('mKmer.KmerRank', 'KmerRank.py'),
        "RemoveDuplicates": pkg_resources.resource_filename('mKmer.RemoveDuplicates', 'RemoveDuplicates.py'),
        "smAnnotation": pkg_resources.resource_filename('mKmer.smAnnotation', 'smAnnotation.py')
    }
    if command not in script_mapping:
        print(f"Error: Unknown command '{command}'. Available commands: {', '.join(script_mapping.keys())}")
        sys.exit(1)
    script_path = script_mapping[command]
    subprocess.run(["python", script_path] + sys.argv[2:])

if __name__ == "__main__":
    main()
