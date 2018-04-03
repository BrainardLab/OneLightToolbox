function applyCorrectedCachetoDirectionObjects(cacheData, DirectionObject, BackgroundObject)

observerAge = DirectionObject.describe.observerAge;

DirectionObject.differentialPrimaryValues = cacheData.data(observerAge).differencePrimary;
BackgroundObject.differentialPrimaryValues = cacheData.data(observerAge).backgroundPrimary;
DirectionObject.describe.correction = cacheData.data(32).correction;

end