import sys
import subprocess

def main():
    if len(sys.argv) < 2:
        print("Usage: mKmer <command> [arguments]")
        sys.exit(1)

    command = sys.argv[1]

    script_mapping = {
        "KmerCell": "mKmer/KmerCell/KmerCell.py",
        "KmerFrequency": "mKmer/KmerFrequency/KmerFrequency.py",
        "KmerGOn": "mKmer/KmerGOn/KmerGOn.py",
        "KmerGOp": "mKmer/KmerGOp/KmerGOp.py",
        "KmerRank": "mKmer/KmerRank/KmerRank.py",
        "RemoveDuplicates": "mKmer/RemoveDuplicates/RemoveDuplicates.py",
        "smAnnotation": "mKmer/smAnnotation/smAnnotation.py"
    }

    if command not in script_mapping:
        print(f"Error: Unknown command '{command}'. Available commands: {', '.join(script_mapping.keys())}")
        sys.exit(1)

    script_path = script_mapping[command]
    subprocess.run(["python", script_path] + sys.argv[2:])

if __name__ == "__main__":
    main()
