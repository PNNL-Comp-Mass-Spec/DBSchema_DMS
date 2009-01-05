/****** Object:  Table [dbo].[T_Material_Locations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Material_Locations](
	[ID] [int] IDENTITY(1000,1) NOT NULL,
	[Tag] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Freezer] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Shelf] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Material_Locations_Shelf]  DEFAULT ('na'),
	[Rack] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Material_Locations_Rack]  DEFAULT ('na'),
	[Row] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Material_Locations_Row]  DEFAULT ('na'),
	[Col] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Material_Locations_Box]  DEFAULT ('na'),
	[Status] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Material_Locations_Status]  DEFAULT ('Active'),
	[Barcode] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Container_Limit] [int] NOT NULL CONSTRAINT [DF_T_Material_Locations_Container_Limit]  DEFAULT ((1)),
 CONSTRAINT [PK_T_Material_Locations] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Material_Locations] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Material_Locations] ON [dbo].[T_Material_Locations] 
(
	[Tag] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Material_Locations_ID_include_Tag] ******/
CREATE NONCLUSTERED INDEX [IX_T_Material_Locations_ID_include_Tag] ON [dbo].[T_Material_Locations] 
(
	[ID] ASC
)
INCLUDE ( [Tag]) WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO
