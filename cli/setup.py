#!/usr/bin/env python3

from setuptools import setup, find_packages

setup(
    name="dbprovision",
    version="1.0.0",
    description="MongoDB Cluster Provisioning CLI",
    author="MongoDB Automation Team",
    python_requires=">=3.8",
    py_modules=["dbprovision"],
    install_requires=[
        "PyYAML>=6.0",
    ],
    entry_points={
        "console_scripts": [
            "dbprovision=dbprovision:main",
        ],
    },
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
)