#!/usr/bin/env python

import pandas as pd
import numpy as np
import argparse
import re

def to_tex(value):
    if type(value) == float:
        return str(int(value)) if not np.isnan(value) and int(value) == value else str(value)
    return str(value)

def run(args: argparse.Namespace):
    df = pd.read_csv("df_student_content.csv")
    template = open("latex/templates/student.tex", "r").read()
    
    fields = set(re.findall(r"\[\w+\]" , template)) - set(["[twoside]", "[SID]"])
    
    if args.verbose: print(f"Generating TeX entry files ...")

    for _, row in df.sort_values("SortName").iterrows():

        if args.verbose:
            print(f"\t{row['Key']:40} {row['Name']}")

        content = template

        for field in fields:
            column = field.strip("[]")
            content = content.replace(field, to_tex(row[column]) if column in df.columns else "")

        with open(f"student_content/{row['Key']}.tex", "wt") as f:
            f.write(content)


if __name__ == "__main__":
    parser = argparse.ArgumentParser("Generate TeX entries for students from df_student_content.csv.")
    parser.add_argument('-v', '--verbose', action="store_true", help='Verbose output')
    args = parser.parse_args()
    run(args)

    

    