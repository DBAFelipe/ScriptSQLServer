-- Gera DROP e CREATE de todos os índices do banco
SET NOCOUNT ON;

DECLARE @IndexScripts TABLE
(
    TableName SYSNAME,
    IndexName SYSNAME,
    DropScript NVARCHAR(MAX),
    CreateScript NVARCHAR(MAX)
);

INSERT INTO @IndexScripts (TableName, IndexName, DropScript, CreateScript)
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    'DROP INDEX [' + i.name + '] ON [' + s.name + '].[' + t.name + '];' AS DropScript,
    'CREATE ' 
        + CASE WHEN i.is_unique = 1 THEN 'UNIQUE ' ELSE '' END
        + i.type_desc + ' INDEX [' + i.name + '] ON [' + s.name + '].[' + t.name + '] ('
        + STUFF((SELECT ', [' + c.name + ']' 
                 + CASE WHEN ic.is_descending_key = 1 THEN ' DESC' ELSE ' ASC' END
                 FROM sys.index_columns ic
                 JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
                 WHERE ic.object_id = t.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0
                 ORDER BY ic.key_ordinal
                 FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,2,'')
        + ')'
        + ISNULL(' INCLUDE (' + STUFF((SELECT ', [' + c.name + ']'
                                       FROM sys.index_columns ic
                                       JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
                                       WHERE ic.object_id = t.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 1
                                       FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,2,'') + ')', '')
        + ';' AS CreateScript
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE i.type > 0 AND i.is_primary_key = 0 AND i.is_unique_constraint = 0;  -- evita PKs e constraints

-- Resultado
SELECT * FROM @IndexScripts;
