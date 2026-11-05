(() => {
    "use strict";
    const $ = (selector) => document.querySelector(selector);
    const cabecera = $("#tablaReporte thead");
    const cuerpo = $("#tablaReporte tbody");
    const mensaje = $("#mensajeReporte");
    const token = document.querySelector('input[name="__RequestVerificationToken"]')?.value ?? "";

    async function cargar() {
        cabecera.replaceChildren(); cuerpo.replaceChildren(); mensaje.textContent = "";
        const tipo = $("#tipoReporte").value;
        let url = `/api/reportes/${tipo}`;
        if (tipo === "ventas") {
            const p = new URLSearchParams();
            if ($("#desde").value) p.set("desde", $("#desde").value);
            if ($("#hasta").value) p.set("hasta", $("#hasta").value);
            url += `?${p.toString()}`;
        }
        if (tipo === "historial-equipos") {
            const id = $("#idEquipo").value;
            if (!id || Number(id) < 1) { mensaje.textContent = "Indique un ID de equipo."; return; }
            url += `/${encodeURIComponent(id)}`;
        }
        try {
            const respuesta = await fetch(url, { credentials: "same-origin", headers: { "Accept": "application/json" } });
            if (!respuesta.ok) throw new Error(`Consulta no disponible (HTTP ${respuesta.status}).`);
            const filas = await respuesta.json();
            if (!Array.isArray(filas) || filas.length === 0) { mensaje.textContent = "No hay resultados para este filtro."; return; }
            const columnas = Object.keys(filas[0]);
            const cab = document.createElement("tr");
            for (const nombre of columnas) { const th = document.createElement("th"); th.textContent = nombre; cab.appendChild(th); }
            cabecera.appendChild(cab);
            for (const fila of filas) {
                const tr = document.createElement("tr");
                for (const nombre of columnas) { const td = document.createElement("td"); td.textContent = fila[nombre] ?? "—"; tr.appendChild(td); }
                cuerpo.appendChild(tr);
            }
            mensaje.textContent = `${filas.length} resultados.`;
        } catch (error) { mensaje.textContent = error.message; }
    }
    $("#btnCargar").addEventListener("click", cargar);
    cargar();
})();
