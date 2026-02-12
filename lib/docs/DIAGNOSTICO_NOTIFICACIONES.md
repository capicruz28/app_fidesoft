# Diagnóstico - Notificaciones Push No Funcionan

## ✅ Lo que SÍ funciona:
- ✅ Tokens FCM se registran correctamente en `ppavac_dispositivo`
- ✅ Badge de pendientes funciona (el endpoint de conteo funciona)
- ✅ Frontend está configurado correctamente

## ❌ Problema identificado:
**El backend NO está enviando notificaciones cuando se crea una solicitud**

---

## 🔍 Pasos de Diagnóstico

### 1. Verificar en la Base de Datos

Ejecuta esta consulta para verificar que los tokens estén correctamente registrados:

```sql
-- Verificar tokens registrados para el aprobador
SELECT 
    d.id_dispositivo,
    d.codigo_trabajador,
    d.token_fcm,
    d.plataforma,
    d.activo,
    d.notif_nuevas,
    d.fecha_registro,
    d.fecha_ultimo_acceso,
    -- Verificar si el usuario es aprobador
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM ppavac_jerarquia j 
            WHERE j.codigo_trabajador_aprobador = d.codigo_trabajador 
            AND j.activo = 'S'
        ) THEN 'SÍ'
        ELSE 'NO'
    END AS es_aprobador
FROM ppavac_dispositivo d
WHERE d.activo = 'S'
ORDER BY d.fecha_registro DESC;
```

**Verificar:**
- [ ] El token del aprobador está registrado (`activo = 'S'`)
- [ ] `notif_nuevas = 'S'` (o NULL, que también es válido)
- [ ] El `codigo_trabajador` corresponde a un aprobador real

---

### 2. Verificar en el Backend - Logs

Cuando creas una solicitud desde el emulador, revisa los logs del backend:

**Buscar estos mensajes:**
- [ ] ¿Se está llamando a la función de envío de notificaciones?
- [ ] ¿Se están identificando los aprobadores correctamente?
- [ ] ¿Se están obteniendo los tokens FCM?
- [ ] ¿Hay errores al enviar con Firebase Admin SDK?

**Ejemplo de lo que deberías ver:**
```
[INFO] Solicitud creada: ID=123, Trabajador=PR014793
[INFO] Identificando aprobadores para área: ADMINISTRACIÓN
[INFO] Aprobadores encontrados: ['APR001', 'APR002']
[INFO] Tokens FCM obtenidos: 2 tokens
[INFO] Enviando notificaciones...
[INFO] Notificaciones enviadas: 2/2 exitosas
```

---

### 3. Verificar Lógica del Backend

El backend debe hacer esto cuando se crea una solicitud (`POST /api/v1/vacaciones/solicitar`):

**Paso 1:** Después de insertar en `ppavac_solicitud`, obtener el `codigo_trabajador` del solicitante

**Paso 2:** Identificar aprobadores:
```sql
SELECT DISTINCT j.codigo_trabajador_aprobador
FROM ppavac_jerarquia j
INNER JOIN trabajadores t ON t.codigo_area = j.codigo_area
WHERE t.codigo_trabajador = @codigo_trabajador_solicitante
  AND j.activo = 'S'
ORDER BY j.nivel ASC
```

**Paso 3:** Obtener tokens FCM:
```sql
SELECT token_fcm
FROM ppavac_dispositivo
WHERE codigo_trabajador IN (@lista_aprobadores)
  AND activo = 'S'
  AND (notif_nuevas = 'S' OR notif_nuevas IS NULL)
```

**Paso 4:** Enviar notificaciones usando Firebase Admin SDK

---

### 4. Probar Manualmente desde Firebase Console

Para verificar que el token funciona, puedes enviar una notificación de prueba desde Firebase Console:

1. Ir a Firebase Console > Cloud Messaging
2. Click en "Send test message"
3. Pegar el `token_fcm` del aprobador (de la base de datos)
4. Escribir título y mensaje
5. Click en "Test"

**Si la notificación llega:** El problema está en el backend (no está enviando cuando se crea solicitud)
**Si la notificación NO llega:** Puede haber un problema con el token o la configuración de Firebase

---

### 5. Verificar Configuración de Firebase Admin SDK

**En el backend, verificar:**
- [ ] Firebase Admin SDK está inicializado correctamente
- [ ] El archivo de credenciales (`serviceAccountKey.json`) está en el lugar correcto
- [ ] Las credenciales son válidas y tienen permisos para enviar notificaciones
- [ ] No hay errores al inicializar Firebase Admin

**Probar inicialización:**
```python
# Python ejemplo
import firebase_admin
from firebase_admin import credentials, messaging

try:
    cred = credentials.Certificate("path/to/serviceAccountKey.json")
    firebase_admin.initialize_app(cred)
    print("Firebase Admin inicializado correctamente")
except Exception as e:
    print(f"Error al inicializar Firebase Admin: {e}")
```

---

### 6. Verificar que se Llame la Función de Envío

**En el endpoint `POST /api/v1/vacaciones/solicitar`:**

Después de insertar la solicitud, debe haber código como:

```python
# Después de crear la solicitud
id_solicitud = resultado_insert.id_solicitud
codigo_trabajador = body.codigo_trabajador
tipo_solicitud = body.tipo_solicitud

# Llamar función para enviar notificaciones
enviar_notificacion_solicitud(
    id_solicitud=id_solicitud,
    tipo_solicitud=tipo_solicitud,
    codigo_trabajador_solicitante=codigo_trabajador
)
```

**Verificar:**
- [ ] ¿Esta función se está llamando?
- [ ] ¿Hay algún try-catch que esté silenciando errores?
- [ ] ¿La función está siendo llamada de forma asíncrona y no está esperando?

---

## 🛠️ Soluciones Comunes

### Problema 1: La función no se está llamando
**Solución:** Agregar la llamada después de crear la solicitud en el endpoint `/api/v1/vacaciones/solicitar`

### Problema 2: No se identifican aprobadores
**Solución:** Verificar la consulta SQL que identifica aprobadores. Puede que el `codigo_area` no coincida.

### Problema 3: No se obtienen tokens
**Solución:** Verificar que los `codigo_trabajador` de los aprobadores coincidan exactamente con los registrados en `ppavac_dispositivo`

### Problema 4: Error al enviar con Firebase Admin SDK
**Solución:** 
- Verificar logs del backend para ver el error específico
- Verificar que las credenciales de Firebase sean correctas
- Verificar que el proyecto Firebase sea el mismo que el `google-services.json`

### Problema 5: Notificaciones se envían pero no llegan
**Solución:**
- Verificar permisos de notificaciones en el dispositivo
- Verificar que el token FCM sea válido
- Verificar que el canal de notificaciones (`fidesoft_channel`) esté configurado correctamente

---

## 📝 Checklist de Verificación Backend

- [ ] La función de envío de notificaciones se llama después de crear solicitud
- [ ] Los aprobadores se identifican correctamente según la jerarquía
- [ ] Los tokens FCM se obtienen de la base de datos correctamente
- [ ] Firebase Admin SDK está inicializado y configurado
- [ ] No hay errores silenciados en el código de envío
- [ ] Los logs muestran que se intenta enviar notificaciones
- [ ] El payload de la notificación tiene el formato correcto

---

## 🧪 Prueba Rápida desde el Backend

Puedes crear un endpoint de prueba para enviar una notificación manualmente:

```python
# Endpoint de prueba: POST /api/v1/notificaciones/test
@router.post("/notificaciones/test")
async def test_notificacion(token_fcm: str):
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title="Prueba de Notificación",
                body="Esta es una notificación de prueba"
            ),
            data={
                "tipo_solicitud": "V",
                "id_solicitud": "999",
                "tipo": "test"
            },
            token=token_fcm,
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(
                    channel_id='fidesoft_channel'
                )
            )
        )
        
        response = messaging.send(message)
        return {"success": True, "message_id": response}
    except Exception as e:
        return {"success": False, "error": str(e)}
```

Usa este endpoint para probar si el token funciona directamente.
