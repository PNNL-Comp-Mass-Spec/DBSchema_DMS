/****** Object:  Table [dbo].[T_LC_Cart_Components] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_LC_Cart_Components](
	[ID] [int] IDENTITY(10,1) NOT NULL,
	[Type] [int] NOT NULL,
	[Status] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Manufacturer] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Part_Number] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Serial_Number] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Property_Number] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Component_Position] [int] NULL,
	[Starting_Date] [datetime] NULL,
 CONSTRAINT [PK_T_LC_Cart_Components] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_LC_Cart_Components] ******/
CREATE NONCLUSTERED INDEX [IX_T_LC_Cart_Components] ON [dbo].[T_LC_Cart_Components] 
(
	[Serial_Number] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_LC_Cart_Components]  WITH CHECK ADD  CONSTRAINT [FK_T_LC_Cart_Components_T_LC_Cart_Component_Postition] FOREIGN KEY([Component_Position])
REFERENCES [T_LC_Cart_Component_Postition] ([ID])
GO
ALTER TABLE [dbo].[T_LC_Cart_Components] CHECK CONSTRAINT [FK_T_LC_Cart_Components_T_LC_Cart_Component_Postition]
GO
ALTER TABLE [dbo].[T_LC_Cart_Components]  WITH CHECK ADD  CONSTRAINT [FK_T_LC_Cart_Components_T_LC_Component_Type] FOREIGN KEY([Type])
REFERENCES [T_LC_Cart_Component_Type] ([ID])
GO
ALTER TABLE [dbo].[T_LC_Cart_Components] CHECK CONSTRAINT [FK_T_LC_Cart_Components_T_LC_Component_Type]
GO
