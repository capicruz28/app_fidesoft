# Checklist de Pruebas - Notificaciones Push en Producción

## ✅ Verificación Pre-Producción

### 1. Registro de Token FCM
- [x] Token se registra correctamente al iniciar sesión
- [x] Registro aparece en la tabla `ppavac_dispositivo`
- [x] Campos guardados correctamente:
  - [x] `token_fcm` (único)
  - [x] `codigo_trabajador`
  - [x] `plataforma` ('A' o 'I')
  - [x] `activo = 'S'`
  - [x] `fecha_registro` y `fecha_ultimo_acceso`

### 2. Configuración Firebase
- [x] `google-services.json` configurado en Android
- [x] Firebase inicializado correctamente
- [x] Permisos de notificaciones solicitados

### 3. Backend
- [x] Endpoint `/api/v1/notificaciones/registrar-token` implementado
- [x] Firebase Admin SDK configurado
- [x] Lógica de envío de notificaciones implementada

---

## 🧪 Pruebas en Producción (2 Equipos)

### Equipo 1: Usuario Normal (Solicitante)
**Pasos:**
1. [ ] Instalar APK de producción en el dispositivo físico
2. [ ] Iniciar sesión con un usuario normal (no aprobador)
3. [ ] Verificar que el token FCM se registre en la base de datos
4. [ ] Crear una solicitud de vacaciones o permiso
5. [ ] Verificar que NO reciba notificación (solo aprobadores reciben)

**Resultado esperado:**
- Token registrado en `ppavac_dispositivo`
- Solicitud creada exitosamente
- No recibe notificación (correcto, no es aprobador)

---

### Equipo 2: Usuario Aprobador
**Pasos:**
1. [ ] Instalar APK de producción en el dispositivo físico
2. [ ] Iniciar sesión con un usuario aprobador
3. [ ] Verificar que el token FCM se registre en la base de datos
4. [ ] Verificar permisos de notificaciones (debe aparecer solicitud de permisos)
5. [ ] Aceptar permisos de notificaciones
6. [ ] Esperar a que el Equipo 1 cree una solicitud
7. [ ] Verificar que reciba notificación push
8. [ ] Tocar la notificación
9. [ ] Verificar que navegue a "Pendientes de Aprobar"

**Resultado esperado:**
- Token registrado en `ppavac_dispositivo`
- Permisos de notificaciones aceptados
- Notificación recibida cuando Equipo 1 crea solicitud
- Al tocar notificación, navega a la pantalla correcta

---

## 🔍 Verificaciones Adicionales

### En la Base de Datos
```sql
-- Verificar tokens registrados
SELECT 
    codigo_trabajador,
    plataforma,
    modelo_dispositivo,
    activo,
    fecha_registro,
    fecha_ultimo_acceso
FROM ppavac_dispositivo
WHERE activo = 'S'
ORDER BY fecha_registro DESC;
```

### En los Logs del Backend
- [ ] Verificar que se envíen notificaciones cuando se crea solicitud
- [ ] Verificar que se identifiquen correctamente los aprobadores
- [ ] Verificar que se obtengan los tokens FCM correctos

### En los Logs de Flutter (usando `flutter logs`)
- [ ] Ver mensaje: "Token FCM obtenido: [token]"
- [ ] Ver mensaje: "Token FCM registrado exitosamente"
- [ ] Ver mensaje: "Notificación recibida en primer plano/segundo plano"

---

## 📱 Escenarios de Prueba

### Escenario 1: Notificación en Primer Plano
1. Equipo 2 tiene la app abierta y visible
2. Equipo 1 crea una solicitud
3. **Resultado esperado:** Notificación aparece como banner en la parte superior

### Escenario 2: Notificación en Segundo Plano
1. Equipo 2 tiene la app en segundo plano (no cerrada)
2. Equipo 1 crea una solicitud
3. **Resultado esperado:** Notificación aparece en la bandeja del sistema

### Escenario 3: App Cerrada
1. Equipo 2 cierra completamente la app
2. Equipo 1 crea una solicitud
3. **Resultado esperado:** Notificación aparece en la bandeja del sistema
4. Al tocar la notificación, la app se abre y navega a "Pendientes de Aprobar"

### Escenario 4: Múltiples Aprobadores
1. Registrar 2+ usuarios aprobadores en diferentes dispositivos
2. Equipo 1 crea una solicitud
3. **Resultado esperado:** Todos los aprobadores reciben la notificación

---

## ⚠️ Problemas Comunes y Soluciones

### Problema: Token no se registra
**Solución:**
- Verificar conexión a internet
- Verificar que el backend esté accesible
- Revisar logs de Flutter para ver el error específico

### Problema: Notificación no se recibe
**Solución:**
- Verificar que el usuario sea aprobador (`/vacaciones/verificar-aprobador`)
- Verificar que el token esté activo en la base de datos
- Verificar permisos de notificaciones en el dispositivo
- Verificar logs del backend para ver si se envió la notificación

### Problema: Navegación no funciona al tocar notificación
**Solución:**
- Verificar que `navigatorKey` esté configurado en `main.dart`
- Verificar que las rutas existan en el `MaterialApp`
- Revisar logs para ver qué ruta se intenta navegar

---

## ✅ Criterios de Éxito

La implementación es exitosa si:
1. ✅ Tokens se registran correctamente en ambos equipos
2. ✅ Usuario aprobador recibe notificaciones cuando se crea solicitud
3. ✅ Usuario normal NO recibe notificaciones (correcto)
4. ✅ Al tocar la notificación, navega a la pantalla correcta
5. ✅ Funciona en primer plano, segundo plano y con app cerrada
6. ✅ Múltiples aprobadores reciben la notificación simultáneamente

---

## 📝 Notas para Producción

1. **Firebase Console:** Puedes usar Firebase Console > Cloud Messaging para enviar notificaciones de prueba antes de probar con solicitudes reales.

2. **Monitoreo:** Considera agregar logging en el backend para monitorear:
   - Tokens registrados
   - Notificaciones enviadas
   - Errores de envío

3. **Tokens Inválidos:** El backend debe manejar tokens inválidos y actualizar `activo = 'N'` cuando Firebase reporte que un token ya no es válido.

4. **Rate Limits:** Firebase tiene límites de envío. Para grandes volúmenes, considera usar batching o FCM HTTP v1 API.
