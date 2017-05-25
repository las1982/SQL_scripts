drop PROC #usp_Test

CREATE PROC #usp_Test @t1 int, @rows INT OUTPUT AS
	declare @sql nvarchar(max), @ParmDefinition nvarchar(500)
	SET @ParmDefinition = N'@t1 int, @rows varchar(30) OUTPUT';
	set @sql = 'set @rows = (select @t1)'
	exec sp_executesql @sql, @ParmDefinition, @t1 = @t1, @rows = @rows output
GO

declare @val int
begin tran
exec #usp_Test @t1 = 66, @rows = @val OUTPUT
rollback tran
print @val