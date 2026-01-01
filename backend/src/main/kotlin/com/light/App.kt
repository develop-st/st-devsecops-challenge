package com.light

import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.engine.*
import io.ktor.server.netty.*
import io.ktor.server.response.*
import io.ktor.server.request.*
import io.ktor.server.routing.*
import org.slf4j.LoggerFactory
import java.sql.DriverManager

private val log = LoggerFactory.getLogger("App")

fun main() {
    embeddedServer(Netty, host = "0.0.0.0", port = 8080) {
        module()
    }.start(wait = true)
}

fun Application.module() {
    routing {
        get("/health") { call.respondText("ok") }

        // ADDED: Readiness probe for Kubernetes
        // K8s needs this to know when the app is ready to receive traffic
        get("/ready") { 
            try {
                val url = System.getenv("DATABASE_URL") ?: "jdbc:postgresql://localhost:5432/postgres"
                val user = System.getenv("DATABASE_USER") ?: "postgres"
                val pass = System.getenv("DATABASE_PASSWORD") ?: ""
                DriverManager.getConnection(url, user, pass).use { conn ->
                    conn.isValid(5)
                }
                call.respondText("ok")
            } catch (e: Exception) {
                log.error("Readiness check failed", e)
                call.respond(HttpStatusCode.ServiceUnavailable, "not ready")
            }
        }

        post("/echo") {
            // SECURITY FIX: Only log headers in debug mode
            // Original code logged all headers which could leak sensitive info like auth tokens
            if (log.isDebugEnabled) {
                log.debug("headers={}", call.request.headers.toMap())
            }
            val body = call.receiveText()
            call.respondText(body)
        }

        get("/user") {
            val idParam = call.request.queryParameters["id"] ?: "1"
            
            // SECURITY FIX: Validate input is a valid integer
            // This prevents malicious input from reaching the database query
            val id = idParam.toIntOrNull()
            if (id == null) {
                call.respond(HttpStatusCode.BadRequest, "Invalid user ID format")
                return@get
            }
            
            val url = System.getenv("DATABASE_URL") ?: "jdbc:postgresql://localhost:5432/postgres"
            val user = System.getenv("DATABASE_USER") ?: "postgres"
            // SECURITY FIX: Removed hardcoded default password - should come from secrets
            val pass = System.getenv("DATABASE_PASSWORD") ?: ""
            
            try {
                DriverManager.getConnection(url, user, pass).use { conn ->
                    // SECURITY FIX: Use PreparedStatement instead of string interpolation
                    // Original code was vulnerable to SQL injection:
                    //   stmt.executeQuery("SELECT name FROM users WHERE id = ${id}")
                    // Attacker could inject: id=1 OR 1=1 to dump all users
                    val stmt = conn.prepareStatement("SELECT name FROM users WHERE id = ?")
                    stmt.setInt(1, id)
                    val rs = stmt.executeQuery()
                    if (rs.next()) {
                        call.respondText(rs.getString("name"))
                    } else {
                        call.respond(HttpStatusCode.NotFound, "User not found")
                    }
                }
            } catch (e: Exception) {
                // SECURITY FIX: Don't expose internal error details to client
                log.error("Database error fetching user id={}", id, e)
                call.respond(HttpStatusCode.InternalServerError, "Internal server error")
            }
        }
    }
}
