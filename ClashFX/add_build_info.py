import subprocess
import datetime
import plistlib
import os


def write_to_info():
    path = "info.plist"

    with open(path, 'rb') as f:
        contents = plistlib.load(f)

    if not contents:
        exit(-1)

    branch = subprocess.check_output(["git", "rev-parse", "--abbrev-ref", "HEAD"]).strip().decode()
    commit = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"]).strip().decode()

    contents["gitBranch"] = branch
    contents["gitCommit"] = commit
    contents["buildTime"] = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")

    # Append commit hash to CFBundleVersion (build number) e.g. "1.0.0+32d8acb"
    current_version = contents.get("CFBundleVersion", "")
    if current_version and "+" not in str(current_version):
        contents["CFBundleVersion"] = f"{current_version}+{commit}"

    with open(path, 'wb') as f:
        plistlib.dump(contents, f, sort_keys=False)

    print(f"  branch:  {branch}")
    print(f"  commit:  {commit}")
    print(f"  version: {contents.get('CFBundleShortVersionString', '')} ({contents['CFBundleVersion']})")


def run():
    print("writing info.plist")
    write_to_info()
    print("done")


if __name__ == "__main__":
    run()
