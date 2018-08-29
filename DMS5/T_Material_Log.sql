/****** Object:  Table [dbo].[T_Material_Log] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Material_Log](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Date] [datetime] NOT NULL,
	[Type] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Item] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Initial_State] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Final_State] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[User_PRN] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Item_Type]  AS (case when [Type] like 'B Material%' then 'Biomaterial' when [Type] like 'Biomaterial%' then 'Biomaterial' when [Type] like 'E Material%' then 'Experiment' when [Type] like 'Experiment%' then 'Experiment' when [Type] like 'R Material%' then 'RefCompound' when [Type] like 'Reference Compound%' then 'RefCompound' when [Type] like 'Container%' then 'Container' when [Type] like '%Container' then 'Container' else [Type] end) PERSISTED NOT NULL,
	[Type_Name_Cached]  AS (case when [Type]='B Material Move' then 'Biomaterial Move' when [Type]='B Material Retirement' then 'Biomaterial Retirement' when [Type]='E Material Move' then 'Experiment Move' when [Type]='E Material Retirement' then 'Experiment Retirement' when [Type]='R Material Move' then 'RefCompound Move' when [Type]='R Material Retirement' then 'RefCompound Retirement' else [Type] end) PERSISTED NOT NULL,
 CONSTRAINT [PK_T_Material_Log] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Material_Log] TO [DDL_Viewer] AS [dbo]
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

GO
/****** Object:  Index [IX_T_Material_Log_Item_Type_Date] ******/
CREATE NONCLUSTERED INDEX [IX_T_Material_Log_Item_Type_Date] ON [dbo].[T_Material_Log]
(
	[Item_Type] ASC,
	[Date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

GO
/****** Object:  Index [IX_T_Material_Log_Type_Name_Cached_Date] ******/
CREATE NONCLUSTERED INDEX [IX_T_Material_Log_Type_Name_Cached_Date] ON [dbo].[T_Material_Log]
(
	[Type_Name_Cached] ASC,
	[Date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Material_Log] ADD  CONSTRAINT [DF_T_Material_Log_Date]  DEFAULT (getdate()) FOR [Date]
GO
