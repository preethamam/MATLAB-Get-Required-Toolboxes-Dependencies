# Required toolboxes and dependencies in MATLAB scripts (requiredToolboxes.m)
[![View Required toolboxes and dependencies in MATLAB scripts on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/182634-required-toolboxes-and-dependencies-in-matlab-scripts) [![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=preethamam/MATLAB-Get-Required-Toolboxes-Dependencies)

Comprehensive dependency auditor for MATLAB projects. This script scans a folder of `.m` source files, determines which MathWorks products/toolboxes each file requires, and writes a structured multi‑section report to `requirements.txt`. It helps you:

- Document project toolbox dependencies for onboarding & reproducibility
- Detect stray or implicit dependencies early (e.g., before CI packaging)
- Identify which files drive each toolbox requirement (impact analysis)
- Maintain a lightweight, versioned dependency manifest alongside code

---

## 1. High‑Level Overview

`requiredToolboxes.m` enumerates MATLAB products used by every non‑ignored `.m` file in a target directory. It leverages the built‑in function `matlab.codetools.requiredFilesAndProducts` to infer dependencies, aggregating both a global toolbox list and per‑file listings, including version and product number metadata when available.

The script produces zero console output until completion (except a final confirmation). All detail is written to `requirements.txt` for easy tracking or diffing in version control.

---

## 2. Key Features

- Global toolbox list: Sorted, de‑duplicated set of all required products.
- Per‑toolbox usage summary: How many files use each toolbox + the file names.
- Per‑file toolbox listing: Exact toolboxes each source file requires.
- File provenance: Each toolbox entry tracks the specific files necessitating it.
- Ignore list support: Exclude helper, scratch, or meta scripts from analysis.
- Single artifact output: Clean, text‑only `requirements.txt` (diff‑friendly).
- Safe failure: Graceful message if no `.m` files remain after ignoring.

---

## 3. File Inventory and Workflow

When you run the script:

1. Collects all `.m` files in `folderPath` (default: current directory `pwd`).
2. Excludes any names listed in `ignoreFiles`.
3. Invokes `matlab.codetools.requiredFilesAndProducts` per file to retrieve a list of product structs (`Name`, `Version`, `ProductNumber`).
4. Aggregates results into a `containers.Map` keyed by toolbox name.
5. Writes structured sections to `requirements.txt`.
6. Prints `Requirements file is created.` once finished.

---

## 4. Requirements

- MATLAB (recommended R2016b or later; `matlab.codetools.requiredFilesAndProducts` exists earlier but robustness improves in later releases).
- Read permission on target folder; write permission to create/overwrite `requirements.txt`.
- Source files must be standard `.m` scripts/functions. (Class definitions and packages are supported insofar as they are reachable by the codetools analysis.)

---

## 5. Usage

### Quick Start (Interactive Desktop)

1. Place `requiredToolboxes.m` in the root of your MATLAB project or add it to path.
2. In MATLAB, `cd` to the project directory you want to audit.
3. Run:

```matlab
requiredToolboxes
```

4. Inspect the generated `requirements.txt`.

### Headless / CI (Batch Mode)

From a terminal / PowerShell (Windows):

```powershell
matlab -batch "requiredToolboxes"
```

Older MATLAB versions (without `-batch`):

```powershell
matlab -nodisplay -nosplash -r "try, requiredToolboxes, catch, exit(1), end; exit(0);"
```

Commit `requirements.txt` into your repository to track dependency drift.

### Custom Target Directory

To scan a folder different from your current working directory:

```matlab
folderPath = 'D:/path/to/project';  % BEFORE running rest of script
requiredToolboxes
```

(Or modify the assignment inside the script permanently.)

### Updating Ignore List

Edit the cell array:

```matlab
ignoreFiles = {
    'scrachPaper.m'
    'requiredToolboxes.m'
    'legacyPrototype.m'
};
```

Use exact file names (case‑sensitive on case‑sensitive file systems).

---

## 6. Output File Structure (`requirements.txt`)

Sections appear in this order:

1. Overall/global required MATLAB products/toolboxes
2. Toolbox usage summary
3. Per‑file required MATLAB products/toolboxes
4. Files analyzed

### Example Excerpt

```
Overall/global required MATLAB products/toolboxes:
  1) Image Processing Toolbox
      Version       : 24.1
      ProductNumber : IPT
  2) Signal Processing Toolbox
      Version       : 24.1
      ProductNumber : SIG

Toolbox usage summary:
  - Image Processing Toolbox : used in 3 file(s)
        • segmentCells.m
        • preprocessImage.m
        • visualizeResults.m
  - Signal Processing Toolbox : used in 1 file(s)
        • filterSignal.m

Per-file required MATLAB products/toolboxes:
  segmentCells.m
    1) Image Processing Toolbox
        Version       : 24.1
        ProductNumber : IPT
  filterSignal.m
    1) Signal Processing Toolbox
        Version       : 24.1
        ProductNumber : SIG
```

(Exact versions/product numbers depend on your installation.)

---

## 7. Customization Points

| Setting                                      | Location                | Purpose                                                             |
| -------------------------------------------- | ----------------------- | ------------------------------------------------------------------- |
| `folderPath`                               | Top of script           | Target folder to scan                                               |
| `ignoreFiles`                              | Top of script           | Exclude specific `.m` files                                       |
| `outputFile`                               | Derived from folderPath | Rename / relocate output if desired                                 |
| Workspace reset (`clc; close all; clear;`) | Top of script           | Remove or comment out if you need current workspace state preserved |

To change output name:

```matlab
outputFile = fullfile(folderPath, 'toolbox_audit.txt');
```

---

## 8. Interpreting Results

- "(Base MATLAB only.)" indicates no toolbox beyond core MATLAB was detected.
- Files listed under a toolbox confirm direct or indirect usage (e.g., a helper function calling a toolbox function).
- A toolbox absent from global list but expected may signal: dynamic usage (e.g., `eval`), runtime addition of paths, reliance on data files, or conditional code not analyzed statically.

---

## 9. Recommended Workflow Integration

- Version Control: Commit `requirements.txt` after significant feature additions; diff to observe new dependencies.
- Code Reviews: Review changes in `requirements.txt` to ensure new toolbox requirements are intentional.
- Continuous Integration: Fail builds if unauthorized toolboxes appear (simple grep-based policy enforcement).
- Release Packaging: Use the file to inform deployment environment provisioning (license check, cluster nodes, etc.).

### Simple CI Guard Example (PowerShell)

```powershell
Select-String -Path requirements.txt -Pattern "Curve Fitting Toolbox" | ForEach-Object {
  Write-Error "Disallowed dependency: Curve Fitting Toolbox"; exit 1
}
```

---

## 10. Limitations

- Dynamic execution (e.g., `eval`, `feval` with variable function names) may hide dependencies.
- Does not inspect non‑MATLAB artifacts (MEX binaries, Simulink models, `.mlx` Live Scripts) unless they are reachable through referenced functions.
- Product numbers may be empty or vary across releases.
- Large projects: Per‑file invocation can be slower; still usually acceptable for typical codebases.
- Ignoring patterns (e.g., all tests) requires manual list maintenance or script extension.

---

## 11. Extending the Script

Potential enhancements:

- Pattern‑based ignore (regex/glob).
- Recursive subfolder scanning (currently only the single directory of `folderPath`).
- JSON/CSV output for machine consumption.
- Separate sections for direct vs transitive dependencies.
- Simulink model scanning via `slreportgen` APIs.
- Command‑line arguments (parsing `varargin`) for more flexible invocation.

---

## 12. Troubleshooting

| Symptom                                          | Possible Cause                                              | Resolution                                                 |
| ------------------------------------------------ | ----------------------------------------------------------- | ---------------------------------------------------------- |
| `Could not open requirements.txt for writing.` | Permission or locked file                                   | Close file, check write permissions, ensure path exists    |
| Empty global list when toolboxes are expected    | Dynamic calls / conditional code                            | Add explicit calls or extend analysis using custom parsers |
| Missing file in output sections                  | File name present in `ignoreFiles` or not a `.m` script | Remove from ignore, ensure extension is `.m`             |
| Versions show unexpected placeholders            | MATLAB release differences                                  | Verify installation with `ver` command                   |

Run `ver` to manually confirm available toolboxes:

```matlab
ver
```

---

## 13. FAQ

**Q: Does it detect dependencies inside nested folders?**
A: Only files directly in `folderPath` (non‑recursive). Extend by replacing the `dir` call with a `genpath` traversal.

**Q: Can I run it without clearing my workspace?**
A: Yes—comment out `clc; close all; clear;` if you need existing variables.

**Q: Are Live Scripts (`.mlx`) supported?**
A: Not directly; convert to `.m` or add a secondary analysis pass.

**Q: How do I add recursion?**
A: Replace the file collection block with:

```matlab
fileList = regexp(genpath(folderPath), pathsep, 'split');
filesArray = {};
for p = 1:numel(fileList)
    if isempty(fileList{p}); continue; end
    mFiles = dir(fullfile(fileList{p}, '*.m'));
    for k = 1:numel(mFiles)
        name = mFiles(k).name;
        if ~ismember(name, ignoreFiles)
            filesArray{end+1,1} = fullfile(fileList{p}, name); %#ok<SAGROW>
        end
    end
end
```

---

## 14. Contributing / Maintenance

Since this is a single self‑contained utility, typical contributions involve:

- Enhancing output formatting (Markdown / JSON)
- Adding recursion or pattern ignores
- Improving performance (batch product query)
- Increasing robustness for dynamic calls

Submit proposed changes along with a before/after diff of `requirements.txt` on a sample project to demonstrate impact.

---

## 15. License

This project is released under the MIT License. You may use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the software under the terms below. Attribution (retaining the copyright notice and permission notice) is required in source distributions. Adding a license header to `requiredToolboxes.m` is optional but recommended if you distribute the script separately.

### MIT License Text

Copyright (c) 2025 Preetham Manjunatha

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

### Attribution Guidance

- Keep this section intact in forks.
- Update the year and holder name as appropriate.
- If integrating into a larger codebase with a different license, clarify dual‑licensing or exceptions in that repository's primary LICENSE file.

### Optional Single-File Header (Copy/Paste if desired)

```matlab
% requiredToolboxes.m (MIT License)
% Copyright (c) 2025 Preetham Manjunatha
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.
```

---

## 16. Quick Reference Cheat Sheet

| Action                    | Code                                  |
| ------------------------- | ------------------------------------- |
| Run audit (GUI)           | `requiredToolboxes`                 |
| Run audit (CI)            | `matlab -batch "requiredToolboxes"` |
| Change target folder      | Edit `folderPath` before run        |
| Ignore a file             | Add name to `ignoreFiles`           |
| Change output file name   | Modify `outputFile` assignment      |
| Check installed toolboxes | `ver`                               |

---

## 17. Sample Automation Script (MATLAB)

```matlab
% Automate auditing + commit if changed
requiredToolboxes;
if isfile('requirements.txt')
    oldHash = ''; newHash = '';
    if isfile('requirements.prev')
        oldHash = string(DataHash(fileread('requirements.prev')));
    end
    newHash = string(DataHash(fileread('requirements.txt')));
    if oldHash ~= newHash
        copyfile('requirements.txt','requirements.prev');
        fprintf('Dependency change detected. Consider committing requirements.txt.\n');
    else
        fprintf('No dependency change.\n');
    end
end
```

(Requires a hashing utility like `DataHash.m` if you add this extension.)

---

## 18. Final Notes

Use this script early in development cycles to enforce transparency of toolbox usage. Maintaining a clean dependency surface reduces licensing surprises and eases portability to new environments.
