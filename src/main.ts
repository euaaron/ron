import {program} from 'commander';
import {version} from '../package.json';

import {remote} from './list/remote.ts';

async function main() {
	program
		.name('ron')
		.description('A simple CLI to manage multiple versions of node.js')
		.version(version);

	program
		.command('change', {isDefault: true})
		.alias('ch')
		.description('change the current version of node.js')
		.argument('[node_version]', 'the version of node.js to use')
		.option('--lts', 'install the latest lts version of node.js')
		.action((argument, option) => {
			if (option.lts) {
				console.log(true);
			} else {
				console.log(false);
			}
		});

	program
		.command('list')
		.alias('ls')
		.description('list all installed versions of node.js')
		.option('-r, --remote', 'list current and past lts versions of node.js')
		.action(async option => {
			if (option.remote || option.r) {
				await remote();
			} else {
				console.log('Sorry, we cannot list local installs yet.');
			}
		});

	program
		.command('remove')
		.alias('rm')
		.argument('<node_version>')
		.option('-a, --all', 'remove all installed versions of node.js')
		.description('remove the specified version of node.js')
		.action((argument, option) => {
			console.log(argument ?? option.all);
		});

	program.combineFlagAndOptionalValue(false);

	program.showHelpAfterError();

	await program.parseAsync(process.argv);
}

main();
