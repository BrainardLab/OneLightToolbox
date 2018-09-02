function compareContrastPrePostCorrection(direction, preValidationIdc, postValidationIdc)
    preValidations = direction.describe.validation(preValidationIdc);
    postValidations = direction.describe.validation(postValidationIdc);

    preContrasts = cat(3,preValidations.contrastActual);
    preContrasts = preContrasts(:,[1 3],:);

    postContrasts = cat(3,postValidations.contrastActual);
    postContrasts = postContrasts(:,[1 3],:);

    preMedian = median(preContrasts,3);
    postMedian = median(postContrasts,3);

    desired = direction.describe.validation(1).contrastDesired;
    desired = desired(:,[1 3]);

    table(desired(:,1),preMedian(:,1),postMedian(:,1),desired(:,2),preMedian(:,2),postMedian(:,2),...
        'VariableNames',{'desired_pos','precorrection_pos', 'postcorrection_post', 'desired_neg','precorrection_neg', 'postcorrection_neg'})
end