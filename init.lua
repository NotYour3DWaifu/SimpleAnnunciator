-- Mod: Anuncios periódicos con colores dinámicos (códigos @w, @r, etc.)
-- Solo jugadores con privilegio "server" pueden usar los comandos.
-- Persistencia en archivo JSON.
-- Version 1.0.1

local modpath = minetest.get_modpath(minetest.get_current_modname())
local storage_path = minetest.get_worldpath() .. "/anuncios.json"

-- Mapeo de códigos de color abreviados
local color_map = {
    w = "#FFFFFF",   -- blanco
    r = "#FF0000",   -- rojo
    g = "#00FF00",   -- verde
    b = "#0000FF",   -- azul
    y = "#FFFF00",   -- amarillo
    o = "#FFA500",   -- naranja
    p = "#800080",   -- púrpura
    c = "#00FFFF",   -- cian
    m = "#FF00FF",   -- magenta
    k = "#000000",   -- negro
}

-- Obtiene el carácter UTF-8 completo en una posición de bytes, junto con su longitud
local function get_char_info(text, byte_pos)
if byte_pos > #text then return nil, 0 end
    local byte = text:byte(byte_pos)
    if not byte then return nil, 0 end
        local bytes_count = 1
        if byte >= 0xFC then      -- 11111100 -> 6 bytes
            bytes_count = 6
            elseif byte >= 0xF8 then  -- 11111000 -> 5 bytes
                bytes_count = 5
                elseif byte >= 0xF0 then  -- 11110000 -> 4 bytes
                    bytes_count = 4
                    elseif byte >= 0xE0 then  -- 11100000 -> 3 bytes
                        bytes_count = 3
                        elseif byte >= 0xC0 then  -- 11000000 -> 2 bytes
                            bytes_count = 2
                            else
                                bytes_count = 1
                                end
                                local char = text:sub(byte_pos, byte_pos + bytes_count - 1)
                                return char, bytes_count
                                end

                                -- Función para parsear el mensaje y aplicar colores (seguro para UTF-8)
                                local function parsear_colores(texto, color_base)
                                if not texto or texto == "" then
                                    return ""
                                    end

                                    local resultado = {}
                                    local color_actual = color_base
                                    local pos = 1
                                    local len = #texto

                                    while pos <= len do
                                        local start = texto:find("@", pos, true)
                                        if not start then
                                            if pos <= len then
                                                table.insert(resultado, minetest.colorize(color_actual, texto:sub(pos)))
                                                end
                                                break
                                                end

                                                if start > pos then
                                                    table.insert(resultado, minetest.colorize(color_actual, texto:sub(pos, start - 1)))
                                                    end

                                                    local next_char, next_len = get_char_info(texto, start + 1)
                                                    if not next_char then
                                                        table.insert(resultado, minetest.colorize(color_actual, "@"))
                                                        pos = start + 1
                                                        else
                                                            if next_char == "@" then
                                                                table.insert(resultado, minetest.colorize(color_actual, "@"))
                                                                pos = start + 1 + next_len
                                                                else
                                                                    local color_nuevo = nil
                                                                    local avance = 0

                                                                    if color_map[next_char] then
                                                                        color_nuevo = color_map[next_char]
                                                                        avance = 1 + next_len
                                                                        else
                                                                            if next_char == "c" or next_char == "(" then
                                                                                local paren_start = start + 1 + next_len
                                                                                if next_char == "c" then
                                                                                    local char_despues_c, len_c = get_char_info(texto, start + 1 + next_len)
                                                                                    if char_despues_c == "(" then
                                                                                        paren_start = start + 1 + next_len
                                                                                        else
                                                                                            table.insert(resultado, minetest.colorize(color_actual, "@c"))
                                                                                            pos = start + 1 + next_len
                                                                                            goto continue
                                                                                            end
                                                                                            else
                                                                                                paren_start = start + 1 + next_len
                                                                                                end

                                                                                                local fin = texto:find(")", paren_start + 1, true)
                                                                                                if fin then
                                                                                                    local hex = texto:sub(paren_start + 1, fin - 1)
                                                                                                    if hex:match("^#%x%x%x%x%x%x$") or hex:match("^#%x%x%x$") then
                                                                                                        color_nuevo = hex
                                                                                                        avance = fin - start + 1
                                                                                                        else
                                                                                                            table.insert(resultado, minetest.colorize(color_actual, texto:sub(start, fin)))
                                                                                                            pos = fin + 1
                                                                                                            goto continue
                                                                                                            end
                                                                                                            else
                                                                                                                table.insert(resultado, minetest.colorize(color_actual, texto:sub(start)))
                                                                                                                pos = len + 1
                                                                                                                goto continue
                                                                                                                end
                                                                                                                else
                                                                                                                    table.insert(resultado, minetest.colorize(color_actual, "@" .. next_char))
                                                                                                                    pos = start + 1 + next_len
                                                                                                                    goto continue
                                                                                                                    end
                                                                                                                    end

                                                                                                                    if color_nuevo then
                                                                                                                        color_actual = color_nuevo
                                                                                                                        pos = start + avance
                                                                                                                        else
                                                                                                                            pos = start + 1
                                                                                                                            end
                                                                                                                            ::continue::
                                                                                                                            end
                                                                                                                            end
                                                                                                                            end

                                                                                                                            return table.concat(resultado)
                                                                                                                            end

                                                                                                                            anuncios = {
                                                                                                                                lista = {},

                                                                                                                                -- Carga los anuncios desde el archivo JSON
                                                                                                                                cargar = function()
                                                                                                                                local file = io.open(storage_path, "r")
                                                                                                                                if file then
                                                                                                                                    local content = file:read("*all")
                                                                                                                                    file:close()
                                                                                                                                    if content and content ~= "" then
                                                                                                                                        local data = minetest.parse_json(content)
                                                                                                                                        if data and type(data) == "table" then
                                                                                                                                            -- Asegurar que cada anuncio tenga color y datos válidos
                                                                                                                                            for _, ann in ipairs(data) do
                                                                                                                                                if not ann.color or ann.color == "" then
                                                                                                                                                    ann.color = "#FFFFFF"
                                                                                                                                                    end
                                                                                                                                                    if not ann.intervalo or ann.intervalo < 1 then
                                                                                                                                                        ann.intervalo = 5 -- valor por defecto
                                                                                                                                                        end
                                                                                                                                                        if not ann.mensaje or ann.mensaje == "" then
                                                                                                                                                            ann.mensaje = "(anuncio vacío)"
                                                                                                                                                            end
                                                                                                                                                            -- Eliminar cualquier timer residual (no se guarda)
                                                                                                                                                            ann.timer = nil
                                                                                                                                                            end
                                                                                                                                                            anuncios.lista = data
                                                                                                                                                            minetest.log("action", "[anuncios] Cargados " .. #anuncios.lista .. " anuncios desde JSON.")
                                                                                                                                                            -- Programar cada anuncio con manejo de errores
                                                                                                                                                            for _, ann in ipairs(anuncios.lista) do
                                                                                                                                                                local ok, err = pcall(anuncios.programar, anuncios, ann)
                                                                                                                                                                if not ok then
                                                                                                                                                                    minetest.log("warning", "[anuncios] Error al programar anuncio: " .. tostring(err))
                                                                                                                                                                    end
                                                                                                                                                                    end
                                                                                                                                                                    return
                                                                                                                                                                    else
                                                                                                                                                                        minetest.log("warning", "[anuncios] El archivo JSON está vacío o corrupto.")
                                                                                                                                                                        end
                                                                                                                                                                        end
                                                                                                                                                                        end
                                                                                                                                                                        anuncios.lista = {}
                                                                                                                                                                        minetest.log("action", "[anuncios] No se encontraron anuncios previos, lista vacía.")
                                                                                                                                                                        end,

                                                                                                                                                                        -- Guarda la lista en el archivo JSON (excluyendo el campo 'timer')
                                                                                                                                                                        guardar = function()
                                                                                                                                                                        -- Crear una copia de la lista sin el campo 'timer'
                                                                                                                                                                        local lista_para_guardar = {}
                                                                                                                                                                        for _, ann in ipairs(anuncios.lista) do
                                                                                                                                                                            table.insert(lista_para_guardar, {
                                                                                                                                                                                color = ann.color,
                                                                                                                                                                                intervalo = ann.intervalo,
                                                                                                                                                                                mensaje = ann.mensaje
                                                                                                                                                                            })
                                                                                                                                                                            end
                                                                                                                                                                            local data = minetest.write_json(lista_para_guardar)
                                                                                                                                                                            if data then
                                                                                                                                                                                local file = io.open(storage_path, "w")
                                                                                                                                                                                if file then
                                                                                                                                                                                    file:write(data)
                                                                                                                                                                                    file:close()
                                                                                                                                                                                    minetest.log("action", "[anuncios] Guardados " .. #anuncios.lista .. " anuncios en JSON.")
                                                                                                                                                                                    else
                                                                                                                                                                                        minetest.log("error", "[anuncios] No se pudo abrir el archivo para guardar.")
                                                                                                                                                                                        end
                                                                                                                                                                                        else
                                                                                                                                                                                            minetest.log("error", "[anuncios] Error al convertir la lista a JSON.")
                                                                                                                                                                                            end
                                                                                                                                                                                            end,

                                                                                                                                                                                            -- Programa el próximo envío de un anuncio
                                                                                                                                                                                            programar = function(ann)
                                                                                                                                                                                            if ann.timer then
                                                                                                                                                                                                ann.timer:cancel()
                                                                                                                                                                                                ann.timer = nil
                                                                                                                                                                                                end
                                                                                                                                                                                                local interval_sec = ann.intervalo * 60
                                                                                                                                                                                                ann.timer = minetest.after(interval_sec, function()
                                                                                                                                                                                                anuncios.enviar(ann)
                                                                                                                                                                                                end)
                                                                                                                                                                                                minetest.log("action", "[anuncios] Programado anuncio cada " .. ann.intervalo .. " min: " .. ann.mensaje)
                                                                                                                                                                                                end,

                                                                                                                                                                                                -- Envía el mensaje con el prefijo "Servidor: " y colores dinámicos
                                                                                                                                                                                                enviar = function(ann)
                                                                                                                                                                                                local color_base = ann.color or "#FFFFFF"
                                                                                                                                                                                                local prefijo = minetest.colorize(color_base, "Servidor: ")
                                                                                                                                                                                                local mensaje_procesado = parsear_colores(ann.mensaje, color_base)
                                                                                                                                                                                                minetest.chat_send_all(prefijo .. mensaje_procesado)
                                                                                                                                                                                                anuncios.programar(ann)
                                                                                                                                                                                                end,

                                                                                                                                                                                                -- Agrega un nuevo anuncio
                                                                                                                                                                                                agregar = function(color, intervalo, mensaje)
                                                                                                                                                                                                if not color or color == "" then
                                                                                                                                                                                                    color = "#FFFFFF"
                                                                                                                                                                                                    end
                                                                                                                                                                                                    if not intervalo or intervalo < 1 then
                                                                                                                                                                                                        intervalo = 5
                                                                                                                                                                                                        end
                                                                                                                                                                                                        if not mensaje or mensaje == "" then
                                                                                                                                                                                                            mensaje = "(anuncio vacío)"
                                                                                                                                                                                                            end
                                                                                                                                                                                                            local ann = {
                                                                                                                                                                                                                color = color,
                                                                                                                                                                                                                intervalo = intervalo,
                                                                                                                                                                                                                mensaje = mensaje
                                                                                                                                                                                                            }
                                                                                                                                                                                                            table.insert(anuncios.lista, ann)
                                                                                                                                                                                                            anuncios.guardar()
                                                                                                                                                                                                            anuncios.programar(ann)
                                                                                                                                                                                                            minetest.log("action", "[anuncios] Agregado nuevo anuncio: " .. mensaje)
                                                                                                                                                                                                            end
                                                                                                                            }

                                                                                                                            -- Cargar anuncios al iniciar el servidor
                                                                                                                            anuncios.cargar()

                                                                                                                            -- Comando para agregar anuncio
                                                                                                                            minetest.register_chatcommand("anunciar", {
                                                                                                                                params = "<color> <tiempo> <mensaje>",
                                                                                                                                description = "Programa un anuncio. Usa @w @r @g @b @y @o @p @c @m @k para colores, o @c(#RRGGBB) para personalizado. Ej: /anunciar red 5 Visita @whttps://blog.com@r ahora.",
                                                                                                                                                          privs = { server = true },
                                                                                                                                                          func = function(name, param)
                                                                                                                                                          if not minetest.check_player_privs(name, { server = true }) then
                                                                                                                                                              return false, "No tienes permiso para usar este comando. Necesitas el privilegio 'server'."
                                                                                                                                                              end

                                                                                                                                                              if param == "" then
                                                                                                                                                                  return false, "Uso: /anunciar <color> <tiempo> <mensaje>"
                                                                                                                                                                  end

                                                                                                                                                                  local color, tiempo_str, mensaje = param:match("^([^%s]+)%s+(%d+)%s+(.+)$")
                                                                                                                                                                  if not color or not tiempo_str or not mensaje then
                                                                                                                                                                      return false, "Formato incorrecto. Uso: /anunciar <color> <tiempo> <mensaje>"
                                                                                                                                                                      end

                                                                                                                                                                      local tiempo = tonumber(tiempo_str)
                                                                                                                                                                      if not tiempo or tiempo < 1 then
                                                                                                                                                                          return false, "El tiempo debe ser un número entero positivo (minutos)."
                                                                                                                                                                          end

                                                                                                                                                                          anuncios.agregar(color, tiempo, mensaje)
                                                                                                                                                                          return true, "Anuncio programado cada " .. tiempo .. " minutos con color " .. color .. ": " .. mensaje
                                                                                                                                                                          end
                                                                                                                            })

                                                                                                                            -- Comando para listar anuncios
                                                                                                                            minetest.register_chatcommand("anuncios", {
                                                                                                                                description = "Lista los anuncios programados.",
                                                                                                                                privs = { server = true },
                                                                                                                                func = function(name, param)
                                                                                                                                if not minetest.check_player_privs(name, { server = true }) then
                                                                                                                                    return false, "No tienes permiso para usar este comando. Necesitas el privilegio 'server'."
                                                                                                                                    end

                                                                                                                                    if #anuncios.lista == 0 then
                                                                                                                                        return true, "No hay anuncios programados."
                                                                                                                                        end
                                                                                                                                        local lines = { "Anuncios programados:" }
                                                                                                                                        for i, ann in ipairs(anuncios.lista) do
                                                                                                                                            table.insert(lines, string.format("%d. Cada %d min - Color: %s - Mensaje: \"%s\"",
                                                                                                                                                                              i, ann.intervalo, ann.color or "#FFFFFF", ann.mensaje))
                                                                                                                                            end
                                                                                                                                            return true, table.concat(lines, "\n")
                                                                                                                                            end
                                                                                                                            })

                                                                                                                            -- Comando para eliminar anuncio (renombrado a /borraranuncio, pero mantengo ambos para compatibilidad)
                                                                                                                            minetest.register_chatcommand("borraranuncio", {
                                                                                                                                params = "<id>",
                                                                                                                                description = "Elimina un anuncio por su ID.",
                                                                                                                                privs = { server = true },
                                                                                                                                func = function(name, param)
                                                                                                                                if not minetest.check_player_privs(name, { server = true }) then
                                                                                                                                    return false, "No tienes permiso para usar este comando. Necesitas el privilegio 'server'."
                                                                                                                                    end

                                                                                                                                    local id = tonumber(param)
                                                                                                                                    if not id or id < 1 or id > #anuncios.lista then
                                                                                                                                        return false, "ID inválido. Usa /anuncios para ver la lista."
                                                                                                                                        end
                                                                                                                                        local ann = anuncios.lista[id]
                                                                                                                                        if ann.timer then
                                                                                                                                            ann.timer:cancel()
                                                                                                                                            ann.timer = nil
                                                                                                                                            end
                                                                                                                                            table.remove(anuncios.lista, id)
                                                                                                                                            anuncios.guardar()
                                                                                                                                            return true, "Anuncio eliminado."
                                                                                                                                            end
                                                                                                                            })

                                                                                                                            -- También mantengo /anunciar_eliminar para quien lo prefiera
                                                                                                                            minetest.register_chatcommand("anunciar_eliminar", {
                                                                                                                                params = "<id>",
                                                                                                                                description = "Elimina un anuncio por su ID.",
                                                                                                                                privs = { server = true },
                                                                                                                                func = function(name, param)
                                                                                                                                return minetest.registered_chatcommands["borraranuncio"].func(name, param)
                                                                                                                                end
                                                                                                                            })
