USE [CSRMAR_D]
GO

DECLARE @RC int
DECLARE @Date date

-- TODO: Set parameter values here.

EXECUTE @RC = [MetricScorecard].[usp_Spotfire_GetMetricMetadata] 
   @Date
GO


USE [CSRMAR_D]
GO

DECLARE @RC int
DECLARE @Date date

-- TODO: Set parameter values here.

EXECUTE @RC = [MetricScorecard].[usp_Spotfire_GetSubMetricScorecard] 
   @Date
GO