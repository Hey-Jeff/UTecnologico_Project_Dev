(() => {
    "use strict";
    const entidad = window.sgcEntidad;
    if (!entidad) return;
    const $ = (selector) => document.querySelector(selector);
    const cabecera = $("#tablaRegistros thead");
    const cuerpo = $("#tablaRegistros tbody");
    const mensaje = $("#mensaje");
    const dialogo = $("#modalRegistro");
    const form = $("#formularioRegistro");
    const campos = $("#camposFormulario");
    const csrf = document.querySelector('input[name="__RequestVerificationToken"]')?.value ?? "";
    let registros = [];
    let accion = "Crear";
    let claveActual = null;
    const nombresClaves = entidad.Claves;
    const ocultos = new Set(["ResumenCriptograficoContrasena"]);

    const rutas = {
        "OrdenTrabajo": (id) => `/api/negocio/ordenes/${id}/cerrar`,
        "OperacionComercial": (id) => `/api/negocio/ventas/${id}/completar`,
        "Cotizacion": (id) => `/api/negocio/cotizaciones/${id}/cambiar-estado`
    };

    const normalizar = (valor) => valor === null || valor === undefined ? "" : String(valor);
    const campoPorNombre = (nombre) => entidad.Campos.find(x => x.Nombre === nombre);
    const claveRegistro = (fila) => nombresClaves.map(nombre => String(fila[nombre])).join(",");
    const mostrar = (texto, esError = false) => {
        mensaje.textContent = texto;
        mensaje.className = "mensaje " + (esError ? "mensaje-error" : "mensaje-exito");
    };
    const limpiarMensaje = () => { mensaje.textContent = ""; mensaje.className = "mensaje"; };

    async function consultar(ruta, opciones = {}) {
        const respuesta = await fetch(ruta, {
            credentials: "same-origin",
            ...opciones,
            headers: {
                "Accept": "application/json",
                ...(opciones.body ? { "Content-Type": "application/json" } : {}),
                ...(opciones.method && opciones.method !== "GET" ? { "RequestVerificationToken": csrf } : {}),
                ...opciones.headers
            }
        });
        let datos = null;
        try { datos = await respuesta.json(); } catch { datos = null; }
        if (!respuesta.ok) {
            const texto = datos?.mensaje ?? datos?.detail ?? `Error HTTP ${respuesta.status}`;
            if (respuesta.status === 401) throw new Error("Sesión vencida. Vuelve a iniciar sesión.");
            throw new Error(texto);
        }
        return datos;
    }

    function crearCelda(fila, texto) {
        const celda = document.createElement("td");
        celda.textContent = normalizar(texto) || "—";
        fila.appendChild(celda);
    }

    function boton(texto, accionClick, clase = "boton-tabla") {
        const elemento = document.createElement("button");
        elemento.type = "button";
        elemento.className = clase;
        elemento.textContent = texto;
        elemento.addEventListener("click", accionClick);
        return elemento;
    }

    function pintar() {
        cabecera.replaceChildren();
        cuerpo.replaceChildren();
        const claves = entidad.Campos
            .filter(x => !ocultos.has(x.Nombre))
            .slice(0, 8)
            .map(x => x.Nombre);
        const filaCabecera = document.createElement("tr");
        for (const nombre of [...claves, "Acciones"]) {
            const celda = document.createElement("th");
            celda.textContent = campoPorNombre(nombre)?.Titulo ?? nombre;
            filaCabecera.appendChild(celda);
        }
        cabecera.appendChild(filaCabecera);

        const filtro = $("#busqueda").value.trim().toLocaleLowerCase("es");
        const visibles = registros.filter(fila => !filtro ||
            Object.values(fila).some(valor => normalizar(valor).toLocaleLowerCase("es").includes(filtro)));
        for (const dato of visibles) {
            const fila = document.createElement("tr");
            for (const nombre of claves) crearCelda(fila, dato[nombre]);
            const acciones = document.createElement("td");
            acciones.className = "acciones-tabla";
            const clave = claveRegistro(dato);
            acciones.appendChild(boton("Ver", () => ver(dato)));
            if (!entidad.SoloLectura) {
                acciones.appendChild(boton("Editar", () => abrirFormulario("Actualizar", dato)));
                if (!(entidad.Esquema === "inventario" && entidad.Tabla === "MovimientoInventario"))
                    acciones.appendChild(boton("Eliminar", () => eliminar(clave), "boton-tabla boton-peligro"));
            }
            if (rutas[entidad.Tabla])
                acciones.appendChild(boton(accionEspecialTexto(), () => accionDeNegocio(clave)));
            fila.appendChild(acciones);
            cuerpo.appendChild(fila);
        }
        $("#contador").textContent = `${visibles.length} registros visibles · Página ${$("#pagina").value}`;
    }

    async function cargar() {
        limpiarMensaje();
        const pagina = Math.max(1, Number($("#pagina").value) || 1);
        $("#pagina").value = pagina;
        const tamano = Number($("#tamanoPagina").value) || 25;
        try {
            registros = await consultar(`${entidad.RutaApi}?pagina=${pagina}&tamanoPagina=${tamano}`);
            pintar();
        } catch (error) {
            mostrar(error.message, true);
            registros = [];
            pintar();
        }
    }

    function tipoInput(tipo) {
        if (tipo.startsWith("DATE")) return tipo.startsWith("DATETIME") ? "datetime-local" : "date";
        if (tipo.startsWith("DECIMAL") || tipo.startsWith("NUMERIC")) return "number";
        if (/^(INT|BIGINT|SMALLINT|TINYINT)/.test(tipo)) return "number";
        if (tipo.startsWith("BIT")) return "checkbox";
        return "text";
    }

    function slug(nombre) {
        return nombre.replace(/([a-z0-9])([A-Z])/g, "$1-$2")
            .replace(/([A-Z])([A-Z][a-z])/g, "$1-$2").toLowerCase();
    }

    function etiquetaValor(registro) {
        const nombres = ["NombreORazonSocial", "NombreArticulo", "NombreModelo", "NombreMarca", "NombreEstado", "NombreRol", "NombreTipo", "NombreMotivo", "NombreCompleto", "NombreProspecto", "CodigoArticulo", "Identificacion", "NombreUsuario"];
        return nombres.map(x => registro[x]).find(x => x !== null && x !== undefined) ??
            Object.values(registro).find(x => typeof x === "string") ?? "Registro";
    }

    async function cargarSelectReferencia(select, referencia, valorInicial) {
        const [esquema, tabla] = referencia.TablaDestino.split(".");
        const ruta = `/api/${esquema.replaceAll("_", "-")}/${slug(tabla)}?pagina=1&tamanoPagina=200`;
        try {
            const opciones = await consultar(ruta);
            select.replaceChildren();
            const vacio = document.createElement("option");
            vacio.value = ""; vacio.textContent = "Seleccione una opción";
            select.appendChild(vacio);
            for (const registro of opciones) {
                const opcion = document.createElement("option");
                opcion.value = registro[referencia.CampoDestino];
                opcion.textContent = `${opcion.value} · ${etiquetaValor(registro)}`;
                select.appendChild(opcion);
            }
            if (valorInicial !== undefined && valorInicial !== null) select.value = String(valorInicial);
        } catch {
            // Si el usuario no puede consultar ese catálogo, se admite el ID manual.
            const reemplazo = document.createElement("input");
            reemplazo.type = "number";
            reemplazo.name = select.name;
            reemplazo.value = valorInicial ?? "";
            reemplazo.placeholder = "Identificador existente";
            select.replaceWith(reemplazo);
        }
    }

    function nombreVisible(nombre) {
        if (nombre === "Contrasena") return "Contraseña";
        if (nombre === "ContrasenaNueva") return "Nueva contraseña";
        const campo = campoPorNombre(nombre);
        if (campo) return campo.Titulo;
        return nombre.replace(/([a-z0-9])([A-Z])/g, "$1 $2").replaceAll("_", " ");
    }

    function camposSolicitados(modo) {
        return entidad.Parametros[modo].filter(p =>
            !nombresClaves.includes(p.Nombre) || modo === "Crear" && !campoPorNombre(p.Nombre)?.Autoincremental)
            .filter(p => ![
                "ResumenCriptograficoContrasena",
                "IdUsuarioCreador", "IdUsuarioRegistro", "IdUsuarioLectura"
            ].includes(p.Nombre))
            .filter(p => !(entidad.Esquema === "inventario" && entidad.Tabla === "MovimientoInventario" && p.Nombre === "IdUsuario"))
            .concat(entidad.Tabla === "Usuario" ? [{ Nombre: modo === "Crear" ? "Contrasena" : "ContrasenaNueva", TipoSql: "NVARCHAR(128)", Opcional: false }] : []);
    }

    async function abrirFormulario(modo, registro = {}) {
        accion = modo;
        claveActual = modo === "Actualizar" ? claveRegistro(registro) : null;
        campos.replaceChildren();
        $("#tituloModal").textContent = modo === "Crear" ? `Nuevo: ${entidad.Titulo}` : `Editar: ${entidad.Titulo}`;
        const promesas = [];
        for (const campo of camposSolicitados(modo)) {
            const contenedor = document.createElement("div");
            contenedor.className = "campo-formulario";
            const etiqueta = document.createElement("label");
            etiqueta.textContent = nombreVisible(campo.Nombre) + (campo.Opcional ? "" : " *");
            const referencia = campoPorNombre(campo.Nombre)?.Referencia;
            const elemento = referencia ? document.createElement("select") : document.createElement("input");
            elemento.name = campo.Nombre;
            elemento.id = `campo-${campo.Nombre}`;
            if (elemento.tagName === "INPUT") elemento.type = campo.Nombre.includes("Contrasena") ? "password" : tipoInput(campo.TipoSql);
            if (elemento.type === "number") {
                elemento.step = /DECIMAL|NUMERIC/.test(campo.TipoSql) ? "0.01" : "1";
            }
            if (elemento.type === "password") elemento.autocomplete = "new-password";
            if (!campo.Opcional && !campoPorNombre(campo.Nombre)?.Nullable && elemento.type !== "checkbox") elemento.required = true;
            const inicial = registro[campo.Nombre];
            if (elemento.type === "checkbox") elemento.checked = inicial === undefined ? true : Boolean(inicial);
            else if (elemento.tagName === "INPUT")
                elemento.value = inicial == null ? "" : String(inicial).slice(0, elemento.type === "date" ? 10 : elemento.type === "datetime-local" ? 16 : undefined);
            else promesas.push(cargarSelectReferencia(elemento, referencia, inicial));
            etiqueta.setAttribute("for", elemento.id);
            contenedor.append(etiqueta, elemento);
            campos.appendChild(contenedor);
        }
        dialogo.showModal();
        await Promise.all(promesas);
    }

    function recopilarCampos() {
        const datos = {};
        for (const campo of camposSolicitados(accion)) {
            const elemento = form.elements.namedItem(campo.Nombre);
            if (!elemento) continue;
            if (elemento.type === "checkbox") { datos[campo.Nombre] = Boolean(elemento.checked); continue; }
            const valor = elemento.value.trim();
            if (valor === "" && campo.Opcional && accion === "Crear") continue;
            datos[campo.Nombre] = valor === "" ? null : valor;
        }
        return datos;
    }

    async function guardar(evento) {
        evento.preventDefault();
        const ruta = entidad.RutaApi + (claveActual ? `/${encodeURIComponent(claveActual)}` : "");
        try {
            const botonGuardar = $("#btnGuardar");
            botonGuardar.disabled = true;
            await consultar(ruta, {
                method: accion === "Crear" ? "POST" : "PUT",
                body: JSON.stringify(recopilarCampos())
            });
            dialogo.close();
            await cargar();
            mostrar("El registro se guardó correctamente.");
        } catch (error) { mostrar(error.message, true); }
        finally { $("#btnGuardar").disabled = false; }
    }

    async function eliminar(clave) {
        if (!window.confirm("¿Confirmas la eliminación o inactivación del registro seleccionado?")) return;
        try {
            await consultar(`${entidad.RutaApi}/${encodeURIComponent(clave)}`, { method: "DELETE" });
            await cargar();
            mostrar("Operación realizada correctamente.");
        } catch (error) { mostrar(error.message, true); }
    }

    async function ver(fila) {
        // Consulta el registro seleccionado para verificar los datos reales en SQL Server.
        try {
            const datos = await consultar(`${entidad.RutaApi}/${encodeURIComponent(claveRegistro(fila))}`);
            const lineas = Object.entries(datos).filter(([campo]) => !ocultos.has(campo))
                .map(([campo, valor]) => `${campo}: ${normalizar(valor)}`);
            window.alert(lineas.join("\n"));
        } catch (error) { mostrar(error.message, true); }
    }

    function accionEspecialTexto() {
        if (entidad.Tabla === "OrdenTrabajo") return "Cerrar orden";
        if (entidad.Tabla === "Cotizacion") return "Cambiar estado";
        return "Completar venta";
    }

    async function accionDeNegocio(clave) {
        const id = clave.split(",")[0];
        const ruta = rutas[entidad.Tabla]?.(id);
        if (!ruta) return;
        let cuerpo = {};
        if (entidad.Tabla === "Cotizacion") {
            const valor = window.prompt("ID del estado de cotización destino (consultar catálogo de estados):");
            if (!valor) return;
            cuerpo = { IdEstadoDestino: Number(valor), Comentario: "Actualizado desde la aplicación SGC" };
        } else if (entidad.Tabla === "OrdenTrabajo") {
            cuerpo = { Observaciones: window.prompt("Observaciones del cierre (opcional):") || "" };
        }
        if (!window.confirm(`¿Confirmas la operación: ${accionEspecialTexto()}?`)) return;
        try {
            await consultar(ruta, { method: "POST", body: JSON.stringify(cuerpo) });
            await cargar();
            mostrar("Operación de negocio completada.");
        } catch (error) { mostrar(error.message, true); }
    }

    $("#btnCrear")?.addEventListener("click", () => abrirFormulario("Crear"));
    $("#btnRecargar").addEventListener("click", cargar);
    $("#busqueda").addEventListener("input", pintar);
    $("#pagina").addEventListener("change", cargar);
    $("#tamanoPagina").addEventListener("change", cargar);
    $("#btnAnterior").addEventListener("click", () => {
        $("#pagina").value = Math.max(1, Number($("#pagina").value) - 1);
        cargar();
    });
    $("#btnSiguiente").addEventListener("click", () => {
        $("#pagina").value = Number($("#pagina").value) + 1;
        cargar();
    });
    $("#btnCancelar").addEventListener("click", () => dialogo.close());
    form.addEventListener("submit", guardar);
    cargar();
})();
