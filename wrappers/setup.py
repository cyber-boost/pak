#!/usr/bin/env python3
"""
PAK.sh  - Universal Package Automation Kit
Python package configuration for pip installation
"""

from setuptools import setup, find_packages
import os

# Read the README file
def read_readme():
    readme_path = os.path.join(os.path.dirname(__file__), 'README.md')
    if os.path.exists(readme_path):
        with open(readme_path, 'r', encoding='utf-8') as f:
            return f.read()
    return "PAK.sh - Universal Package Automation Kit "

# Read version from  script
def get_version():
    _path = os.path.join(os.path.dirname(__file__), 'pak-sh')
    if os.path.exists(_path):
        with open(_path, 'r', encoding='utf-8') as f:
            for line in f:
                if 'PAK_VERSION=' in line:
                    return line.split('=')[1].strip().strip('"')
    return "3.0.0"

setup(
    name="pak-sh",
    version=get_version(),
    description="PAK.sh - Universal Package Automation Kit ",
    long_description=read_readme(),
    long_description_content_type="text/markdown",
    author="PAK.sh Team",
    author_email="team@pak.sh",
    url="https://pak.sh",
    project_urls={
        "Documentation": "https://pak.sh/docs",
        "Source": "https://github.com/cyber-boost/pak",
        "Issues": "https://github.com/cyber-boost/pak/issues",
    },
    packages=find_packages(),
    py_modules=[],
    scripts=["pak-sh"],
    entry_points={
        "console_scripts": [
            "pak-sh=pak_sh:main",
            "pak=pak_sh:main",
        ],
    },
    classifiers=[
        "Development Status :: 5 - Production/Stable",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Topic :: Software Development :: Build Tools",
        "Topic :: Software Development :: Libraries :: Python Modules",
        "Topic :: System :: Software Distribution",
        "Topic :: Utilities",
    ],
    keywords=[
        "pak",
        "package",
        "automation",
        "deployment",
        "npm",
        "pypi",
        "cargo",
        "nuget",
        "packagist",
        "docker",
        "cli",
        "tool",
        "",
        "package-manager",
        "devops",
        "ci-cd",
    ],
    python_requires=">=3.7",
    install_requires=[],
    extras_require={
        "dev": [
            "pytest>=6.0",
            "pytest-cov>=2.0",
            "black>=21.0",
            "flake8>=3.8",
            "mypy>=0.800",
        ],
        "test": [
            "pytest>=6.0",
            "pytest-cov>=2.0",
        ],
    },
    include_package_data=True,
    zip_safe=False,
    platforms=["linux", "darwin", "win32"],
    license="MIT",
    license_files=["LICENSE"],
) 