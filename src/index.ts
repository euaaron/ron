import {program} from 'commander';

import {remote} from './list/remote';

async function main() {
	program
		.name('ron')
		.description('A simple CLI to manage multiple versions of node.js')
		.version(process.env.npm_package_version ?? '0.0.0');

	program
		.command('change', {isDefault: true})
		.alias('ch')
		.description('# change the running version of node.js')
		.argument('[node_version]', '# the version of node.js to use')
		.option('--lts', '# install the latest lts version of node.js')
		.action((argument, option) => {
			if (argument) {
				console.log('');
			}
			if (option.lts) {
				console.log(true);
			} else {
				console.log(false);
			}
		});

	program
		.command('list')
		.alias('ls')
		.description('# list node.js versions available')
		.option('-r, --remote', '# list node.js versions available to install')
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
		.description('# remove the specified version of node.js')
		.option('-a, --all', '# remove all installed versions of node.js')
		.action((argument, option) => {
			console.log(argument ?? option.all);
		});

	program.combineFlagAndOptionalValue(false);

	program.showHelpAfterError();

	await program.parseAsync(process.argv);
}

main();
