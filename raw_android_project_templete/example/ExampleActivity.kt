package com.androidrtc.chat.modules.basefun.example

import android.content.Context
import android.content.Intent
import com.androidrtc.chat.R
import com.androidrtc.chat.databinding.ActivityExampleBinding
import com.androidtool.common.base.BaseBindingActivity
import com.google.android.material.tabs.TabLayoutMediator

class ExampleActivity : BaseBindingActivity<ActivityExampleBinding>() {

    private var tabLayoutMediator: TabLayoutMediator? = null

    override fun initView() {
        title = "ExampleActivity"

        binding.viewPager.isSaveEnabled = false

        val adapter = ExampleTabsAdapter(supportFragmentManager, lifecycle).apply {
            addFragment(
                ExamplePagingListFragment.newInstance(tabKey = TAB_LEFT),
                getString(R.string.example_tab_left)
            )
            addFragment(
                ExamplePagingListFragment.newInstance(tabKey = TAB_RIGHT),
                getString(R.string.example_tab_right)
            )
        }
        binding.viewPager.adapter = adapter

        tabLayoutMediator?.detach()
        tabLayoutMediator = TabLayoutMediator(binding.tabLayout, binding.viewPager) { tab, position ->
            tab.text = adapter.getPageTitle(position)
            binding.viewPager.setCurrentItem(tab.position, true)
        }.apply { attach() }
    }

    override fun onDestroy() {
        tabLayoutMediator?.detach()
        tabLayoutMediator = null
        super.onDestroy()
    }

    companion object {
        private const val TAB_LEFT = "left"
        private const val TAB_RIGHT = "right"

        fun start(context: Context) {
            context.startActivity(Intent(context, ExampleActivity::class.java))
        }
    }
}

