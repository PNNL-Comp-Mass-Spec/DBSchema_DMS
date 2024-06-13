/****** Object:  Table [dbo].[T_Query_Row_Count_Default_Refresh_Interval] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Query_Row_Count_Default_Refresh_Interval](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Object_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Refresh_Interval_Hours] [numeric](9, 3) NOT NULL,
	[Entered] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Query_Row_Count_Default_Refresh_Interval] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Query_Row_Count_Default_Refresh_Interval_Object_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_Query_Row_Count_Default_Refresh_Interval_Object_Name] ON [dbo].[T_Query_Row_Count_Default_Refresh_Interval]
(
	[Object_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Query_Row_Count_Default_Refresh_Interval] ADD  CONSTRAINT [DF_T_Query_Row_Count_Default_Refresh_Interval_Refresh_Interval_Hours]  DEFAULT ((4)) FOR [Refresh_Interval_Hours]
GO
ALTER TABLE [dbo].[T_Query_Row_Count_Default_Refresh_Interval] ADD  CONSTRAINT [DF_T_Query_Row_Count_Default_Refresh_Interval_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
