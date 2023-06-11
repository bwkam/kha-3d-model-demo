let project = new Project('New Project');

// assets 
project.addAssets('Assets/**', {
     nameBaseDir: 'Assets',
     destination: '{dir}/{name}',
     name: '{dir}/{name}'
});

// shaders
project.addShaders('Shaders/**');

// source code 
project.addSources('Sources');

// libraries
project.addLibrary('gltf');
project.addLibrary('zui');

resolve(project);
