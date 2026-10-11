package com.widgetskit.widgets_kit

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotSame
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.runBlocking

class WidgetDataStoreTest {
  private val prefs = FakeSharedPreferences()
  private val store = WidgetDataStore(prefs)

  @Test
  fun `saving a string stores it and reports it was persisted`() = runBlocking {
    val outcome = store.save("id", "hello")

    assertEquals(WidgetDataStore.SaveOutcome.Saved(persisted = true), outcome)
    assertEquals("hello", store.get("id", null))
  }

  @Test
  fun `an unsupported type is rejected without writing anything`() = runBlocking {
    val outcome = store.save("id", listOf(1, 2))

    val invalid = assertIs<WidgetDataStore.SaveOutcome.InvalidType>(outcome)
    assertTrue(invalid.typeName.isNotEmpty())
    assertEquals(0, prefs.commitCount)
    assertTrue(prefs.values.isEmpty())
  }

  @Test
  fun `a double round trips as a double and not as a long`() = runBlocking {
    store.save("price", 12.5)

    assertEquals(12.5, store.get("price", null))
  }

  @Test
  fun `a long stays a long beside a stored double`() = runBlocking {
    store.save("count", 7L)
    store.save("price", 12.5)

    assertEquals(7L, store.get("count", null))
  }

  @Test
  fun `saving null removes the value and its double marker`() = runBlocking {
    store.save("price", 12.5)

    store.save("price", null)

    assertNull(store.get("price", null))
    assertFalse(prefs.values.containsKey("widgets_kit.double.price"))
  }

  @Test
  fun `a missing key returns the default`() = runBlocking {
    assertEquals("fallback", store.get("nope", "fallback"))
  }

  @Test
  fun `the disk write does not happen on the calling thread`() = runBlocking {
    val caller = Thread.currentThread()

    store.save("id", "hello")

    assertNotSame(caller, prefs.commitThread)
  }
}
