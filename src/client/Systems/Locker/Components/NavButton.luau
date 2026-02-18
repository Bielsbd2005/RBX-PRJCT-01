--[[
	NavButton
	Botón de opción de navegación para el Locker.
	Muestra una imagen, título, y crece cuando está seleccionado.

	Props:
		name: string              — Nombre del botón
		title: string             — Texto visible (ej. "Weapon Skins")
		image: string             — Asset ID de la imagen
		layoutOrder: number       — Orden en el layout
		isSelected: StateObject   — Fusion state: true cuando está seleccionado
		onClick: (() -> ())?      — Callback al hacer click
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.fusion)
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local Computed = Fusion.Computed
local Spring = Fusion.Spring

local Constants = require(script.Parent.StoreConstants)

type NavButtonProps = {
	name: string,
	title: string,
	image: string,
	layoutOrder: number,
	isSelected: Fusion.StateObject<boolean>,
	onClick: (() -> ())?,
}

local function NavButton(scope: Fusion.Scope<typeof(Fusion)>, props: NavButtonProps)
    -- Animación de tamaño: crece cuando está seleccionado
    local sizeSpring = Spring(scope, Computed(scope, function(use)
        if use(props.isSelected) then
            -- El crecimiento ahora se expandirá hacia la izquierda
            return UDim2.fromScale(1.509, 1)
        else
            return UDim2.fromScale(1, 1)
        end
    end), 30, 0.7)

    -- Color de fondo reactivo
    local backgroundColor = Computed(scope, function(use)
        return use(props.isSelected) and Constants.Colors.NavOptionActive or Constants.Colors.TabInactive
    end)

    -- Wrapper Frame para mantener el layout
    return scope:New "Frame" {
        Name = props.name .. "Wrapper",
        BackgroundTransparency = 1,
        LayoutOrder = props.layoutOrder,
        Size = UDim2.fromScale(1, 0.301205),

        [Children] = {
            scope:New "ImageButton" {
                Name = props.name,
                -- CAMBIO AQUÍ: AnchorPoint en X = 1 (Derecha)
                AnchorPoint = Vector2.new(1, 0.5),
                AutoButtonColor = false,
                BackgroundColor3 = backgroundColor,
                Image = Constants.Assets.Placeholder,
                ImageTransparency = 1,
                -- CAMBIO AQUÍ: Posición en X = 1 para que pegue a la derecha del Wrapper
                Position = UDim2.fromScale(1, 0.5),
                Size = sizeSpring,

                [OnEvent "Activated"] = function()
                    if props.onClick then
                        props.onClick()
                    end
                end,

                [Children] = {
                    -- El resto de los hijos se mantienen igual
                    scope:New "UICorner" { Name = "UICorner" },

                    scope:New "ImageLabel" {
                        Name = "OptionImage",
                        BackgroundTransparency = 1,
                        Image = props.image,
                        Position = UDim2.fromScale(0, -0.199615),
                        ScaleType = Enum.ScaleType.Fit,
                        Size = UDim2.fromScale(1, 0.848708),
                    },

                    scope:New "TextLabel" {
                        Name = "Title",
                        BackgroundTransparency = 1,
                        FontFace = Font.new(
                            "rbxasset://fonts/families/SourceSansPro.json",
                            Enum.FontWeight.Bold,
                            Enum.FontStyle.Normal
                        ),
                        Position = UDim2.fromScale(0, 0.668258),
                        Size = UDim2.fromScale(1, 0.246377),
                        Text = props.title,
                        TextColor3 = Color3.new(1, 1, 1),
                        TextScaled = true,

                        [Children] = {
                            scope:New "UIStroke" {
                                Name = "InnerStroke",
                                Thickness = 4,
                            },
                        },
                    },

                    scope:New "UIStroke" {
                        Name = "BorderStroke",
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                        Thickness = 4,
                    },
                },
            },
        },
    }
end

return NavButton
