:CONNECT GCWCPSQLV00453
USE [CSRMAR_P]
SELECT
	 453
	,[DestinationSystem]
    ,[HasCompleted]
    ,[LoadDate]
FROM [dbo].[vws_SourceSystem_LastUpdateDate]
--WHERE [DestinationSystem] = 'CIC';
GO

:CONNECT GCWCNSQLV00645
USE [CSRMAR_Q]
SELECT
	 645
	,[DestinationSystem]
    ,[HasCompleted]
    ,[LoadDate]
FROM [CSRMAR_Q].[dbo].[vws_SourceSystem_LastUpdateDate]
--WHERE [DestinationSystem] = 'CIC';
GO