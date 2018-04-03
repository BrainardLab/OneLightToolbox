function [ fakeCache ] = makeFakeCache(DirectionObject)

observerAge = DirectionObject.describe.observerAge;

fakeCache.computeMethod = 'ReceptorIsolate';
fakeCache.data(observerAge).params.receptorIsolateMode = 'Standard';
fakeCache.data(observerAge).backgroundPrimary = DirectionObject.describe.backgroundNominal.differentialPrimaryValues;
fakeCache.data(observerAge).differencePrimary = DirectionObject.differentialPrimaryValues;
fakeCache.data(observerAge).describe.photoreceptors = DirectionObject.describe.directionParams.photoreceptorClasses;
fakeCache.data(observerAge).describe.T_receptors = DirectionObject.describe.directionParams.T_receptors;

end