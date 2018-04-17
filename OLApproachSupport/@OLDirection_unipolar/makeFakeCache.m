function [ fakeCache ] = makeFakeCache(direction, background)

fakeCache.computeMethod = 'ReceptorIsolate';
fakeCache.data(32).params.receptorIsolateMode = 'Standard';
fakeCache.data(32).backgroundPrimary = background.differentialPrimaryValues;
fakeCache.data(32).differencePrimary = direction.differentialPrimaryValues;

fakeCache.data(32).describe.photoreceptors = direction.describe.directionParams.photoreceptorClasses;
fakeCache.data(32).describe.T_receptors = direction.describe.T_receptors;

end