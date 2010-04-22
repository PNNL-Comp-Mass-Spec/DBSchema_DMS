/****** Object:  Table [dbo].[T_LC_Cart_Positions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_LC_Cart_Positions](
	[ID] [int] NOT NULL,
	[Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Component_Type] [int] NOT NULL,
	[Comment] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_LC_Cart_Positions] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_LC_Cart_Positions]  WITH CHECK ADD  CONSTRAINT [FK_T_LC_Cart_Positions_T_LC_Cart_Component_Type] FOREIGN KEY([Component_Type])
REFERENCES [T_LC_Cart_Component_Type] ([ID])
GO
ALTER TABLE [dbo].[T_LC_Cart_Positions] CHECK CONSTRAINT [FK_T_LC_Cart_Positions_T_LC_Cart_Component_Type]
GO
