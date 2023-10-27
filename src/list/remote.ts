export async function remote() {
	try {
		let versions = await fetch('https://nodejs.org/dist/index.json').then(res =>
			res.json(),
		);

		versions = versions
			.filter((item: any) => item.lts)
			.map((item: any) => item.version);

		const total = versions.length;
		const quarter = Math.ceil(total / 4);
		const column1: string[] = [];
		const column2: string[] = [];
		const column3: string[] = [];
		const column4: string[] = [];
		versions.forEach((version: string, index: number) => {
			if (index < quarter) {
				column1.push(version);
			} else if (index < quarter * 2) {
				column2.push(version);
			} else if (index < quarter * 3) {
				column3.push(version);
			} else {
				column4.push(version);
			}
		});
		console.log('Node.js LTS veersions available to download:\n');
		for (let i = 0; i < quarter; i++) {
			console.log(
				`${column1[i]}    \t${column2[i] || ''}    \t${column3[i] || ''}    \t${
					column4[i] || ''
				}`,
			);
		}
		console.log('\nNow you probably will want to run');
		console.log(
			'  $ ron --lts\t-> to install the latest lts version, or for example',
		);
		console.log(
			'  $ ron 16\t-> to install the latest 16 version (v16.20.2), or ',
		);
		console.log(
			'  $ ron 14.21.5\t-> to install node.js version 14.21.5 or any other version available.',
		);
	} catch (err) {
		console.error('Could not fetch remote versions. Are you offline?');
		return;
	}
}
