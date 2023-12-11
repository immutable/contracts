
import fs from 'fs';
import replace from 'replace-in-file';
import forks from '../forks/forks.json';
import main from '../package.json';

forks.forEach(fork => {
    const dest = `contracts/${fork.name}`;
    fs.rmSync(dest, { recursive: true, force: true });
    fs.cpSync(`forks/${fork.contracts}`, dest, {recursive: true});

    const rmTemplate = `DO NOT MODIFY THESE CONTRACTS DIRECTLY. This folder has been automatically extracted from ${fork.upstream} via a submodule in this repository's forks directory. See the upstream repository for full context.`

    fs.writeFileSync(`${dest}/README.md`, rmTemplate);

    if (fork.dependencies) {
        const pkg = JSON.parse(fs.readFileSync(`forks/${fork.name}/package.json`));
        fork.dependencies.forEach(dep => {
            const depVersion = pkg.dependencies[dep] ? pkg.dependencies[dep] : pkg.devDependencies[dep];

            const mainDepVersion = (main.dependencies as any)[dep];
            // What happens if the version clashes!
            if (mainDepVersion && depVersion != mainDepVersion) {
                // Create a custom name e.g. @openzeppelin/contracts/seaport
                const customDepName = `${dep}/${fork.name}`;
                (main.dependencies as any)[customDepName] = `npm:${dep}@${depVersion}`;
                // Now replace all of the references to the dependency
                // inside the fork's copied contracts folder
                // e.g. '@openzeppelin/contracts/x/y.sol --> @openzeppelin/contracts/seaport/x/y.sol
                replace.sync({
                    from: dep,
                    to: customDepName,
                    files: [`${dest}/**/*.sol`]
                });
            } else {
                // No clash in the dependencies, just add it
                (main.dependencies as any)[dep] = depVersion;
            }
        });

    }
});

// Update our main package.json
fs.writeFileSync('package.json', JSON.stringify(main, null, 2), 'utf8');

