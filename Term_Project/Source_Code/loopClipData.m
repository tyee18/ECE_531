%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File Name:   loopClipData.m
% Author:      Taylor Yee
% Description: This file serves as a convenience script to loop through all
%              audio clips provided and output data needed for report.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all; close all;

%% Loop through all possible clips and grab data for each
%% Note that in terms of sub-bass analysis, 'Jack and Diane - John Mellencamp'
%% is unable to analyze unless reading at least 60.0s - comment out for anything less
audioFileList = [{'bedchem_sabrinacarpenter'},   {'diewasmile_brunomarsladygaga'}, ...
                 {'dreams_fleetwoodmac'},        {'everybreathyoutake_thepolice'}, ...
                 {'guyforthat_postmalone'},      {'jackanddiane_johnmcamp'},    ...
                 {'mypromisedland_josiahqueen'}, {'needyounow_ladya'}, ...
                 {'pinkponyclub_chappellroan'},  {'youshookmeallnightlong_acdc'}];

songIDList = [{'Bed Chem - Sabrina Carpenter'},    {'Die With a Smile - Bruno Mars feat. Lady Gaga'}, ...
              {'Dreams - Fleetwood Mac'},          {'Every Breath You Take - The Police'}, ...
              {'Guy For That - Post Malone'},      {'Jack and Diane - John Mellencamp'}, ...
              {'My Promised Land - Josiah Queen'}, {'Need You Now - Lady A'}, ...
              {'Pink Pony Club - Chappell Roan'},  {'You Shook Me All Night Long - ACDC'}];

% User-define-able parameters
bpfFreqZone = [60 250];
beatThreshold = 0.25;
fs = 48000;
secondsToRead = 60;

%% Adjust this based on how you structure your codebase - the important
%% part is to make sure the filepath points directly to the audio clip(s)
%% to be analyzed. This assumes all the clips are in the same directory,
%% but this can also be dynamically updated.
filepath = [pwd filesep];

for songInd = 1:length(audioFileList)
    thisSong   = strcat(filepath, string(audioFileList(songInd)));
    thisSongID = string(songIDList(songInd));
    mainTestDriver(thisSong, thisSongID, bpfFreqZone, beatThreshold, ...
        fs, secondsToRead);
end

