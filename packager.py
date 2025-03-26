import os
import zipfile


def package_files(output_filename="package.zip"):
    ignored_files = {"packager.py", ".git", ".gitignore", output_filename}

    with zipfile.ZipFile(output_filename, "w") as zipf:
        for root, dirs, files in os.walk("."):
            for file in files:
                file_path = os.path.relpath(os.path.join(root, file), ".")
                if not any(
                    file_path.startswith(ignored_file) for ignored_file in ignored_files
                ):
                    print(f"Adding {file_path}")
                    zipf.write(file_path, "banshu/" + file_path)


if __name__ == "__main__":
    package_files("banshu_0.0.3.zip")
