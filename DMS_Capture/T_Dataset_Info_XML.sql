/****** Object:  Table [dbo].[T_Dataset_Info_XML] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Dataset_Info_XML](
	[Dataset_ID] [int] NOT NULL,
	[DS_Info_XML] [xml] NULL,
	[Cache_Date] [datetime] NULL,
	[Ignore] [bit] NOT NULL,
 CONSTRAINT [PK_T_Dataset_Info_XML] PRIMARY KEY CLUSTERED 
(
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Dataset_Info_XML] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_Dataset_Info_XML] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Dataset_Info_XML] ON [dbo].[T_Dataset_Info_XML]
(
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Dataset_Info_XML] ADD  CONSTRAINT [DF_T_Dataset_Info_XML_Cache_Date]  DEFAULT (getdate()) FOR [Cache_Date]
GO
ALTER TABLE [dbo].[T_Dataset_Info_XML] ADD  CONSTRAINT [DF_T_Dataset_Info_XML_Ignore]  DEFAULT ((0)) FOR [Ignore]
GO
